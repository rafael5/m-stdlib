/* m-stdlib STDFS — libc read(2) / write(2) glue for byte-faithful I/O.
 *
 * Three public entry points, one shape:
 *
 *   ydb_long_t stdfs_writeBytes (ydb_string_t *path, ydb_string_t *data);
 *   ydb_long_t stdfs_appendBytes(ydb_string_t *path, ydb_string_t *data);
 *   ydb_long_t stdfs_readBytes  (ydb_string_t *path, ydb_string_t *out);
 *
 * Plus two probes:
 *
 *   ydb_long_t stdfs_available(void);          // 1 = .so loads + open() works
 *   ydb_long_t stdfs_lasterror(ydb_string_t *out);
 *
 * Returns 1 on success, 0 on failure (caller reads stdfs_lasterror() for
 * detail). All buffers are byte-safe — no NUL-termination assumptions on the
 * data side; path is copied to a NUL-terminated stack buffer because open(2)
 * needs a C string.
 *
 * Why this exists: the YDB SEQ-device stream-mode close finalises the on-disk
 * file with a trailing LF (per POSIX text-file convention). Byte-faithful
 * round-trips of arbitrary payloads — gzipped bytes, JPEGs, signed binaries —
 * need raw read(2) / write(2) at the libc layer. Native append also avoids
 * the byte-0 quirk where the first WRITE after `OPEN dev:(append)` lands at
 * position 0 instead of EOF.
 *
 * Last-error reporting: a single 1-KB process-static buffer holds the most
 * recent error message. Cleared at the start of every public call; populated
 * on failure. M reads it via stdfs_lasterror().
 *
 * Thread safety: YDB's MUMPS process model is single-threaded per process;
 * the static buffer is fine. If a future host-call entrypoint becomes
 * multi-threaded, switch to __thread storage class.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

/* YDB's libyottadb.h is the source of truth for ydb_string_t / ydb_long_t.
 * If unavailable at compile time (host without YDB installed), tools/build-
 * callouts.sh's ydb_include_flag() drops the -I flag and we fall back to
 * the inline declarations below. The on-disk ABI matches what YDB ships. */
#if defined(__has_include)
#  if __has_include(<libyottadb.h>)
#    include <libyottadb.h>
#    define HAVE_LIBYOTTADB_H 1
#  endif
#endif

#ifndef HAVE_LIBYOTTADB_H
typedef struct {
    unsigned int length;
    char *address;
} ydb_string_t;
typedef long ydb_long_t;
#endif

#define STDFS_PATH_MAX     4096
#define STDFS_OUT_BUFSIZE  (16 * 1024 * 1024)
#define STDFS_ERR_BUFSIZE  1024

static char g_lasterr[STDFS_ERR_BUFSIZE];

static void clear_err(void) {
    g_lasterr[0] = '\0';
}

static void set_err(const char *msg) {
    if (!msg) { g_lasterr[0] = '\0'; return; }
    size_t n = strlen(msg);
    if (n >= STDFS_ERR_BUFSIZE) n = STDFS_ERR_BUFSIZE - 1;
    memcpy(g_lasterr, msg, n);
    g_lasterr[n] = '\0';
}

static void set_err_errno(const char *prefix) {
    char buf[STDFS_ERR_BUFSIZE];
    int saved = errno;
    snprintf(buf, sizeof(buf), "%s%s", prefix, strerror(saved));
    set_err(buf);
}

/* Copy path->{address,length} into a NUL-terminated C string. Returns 0 on
 * success, -1 if the path overflows STDFS_PATH_MAX. */
static int copy_path(ydb_string_t *path, char *dst) {
    size_t n;
    if (!path || !path->address) {
        set_err(",U-STDFS-BAD-PATH-NULL,");
        return -1;
    }
    n = (size_t)path->length;
    if (n >= STDFS_PATH_MAX) {
        set_err(",U-STDFS-BAD-PATH-TOO-LONG,");
        return -1;
    }
    memcpy(dst, path->address, n);
    dst[n] = '\0';
    return 0;
}

/* Loop write(2) until the full buffer is flushed or an error occurs. Returns
 * 0 on success; sets errno + returns -1 on failure. */
static int write_all(int fd, const char *buf, size_t n) {
    size_t off = 0;
    while (off < n) {
        ssize_t w = write(fd, buf + off, n - off);
        if (w < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        off += (size_t)w;
    }
    return 0;
}

/* ---------- writeBytes ---------- */

ydb_long_t stdfs_writeBytes(ydb_string_t *path, ydb_string_t *data) {
    char pathbuf[STDFS_PATH_MAX];
    int fd;

    clear_err();
    if (copy_path(path, pathbuf) != 0) return 0;

    fd = open(pathbuf, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) {
        set_err_errno(",U-STDFS-OPEN-FAIL-");
        return 0;
    }

    if (data && data->address && data->length > 0) {
        if (write_all(fd, data->address, (size_t)data->length) != 0) {
            set_err_errno(",U-STDFS-WRITE-FAIL-");
            close(fd);
            return 0;
        }
    }

    if (close(fd) != 0) {
        set_err_errno(",U-STDFS-CLOSE-FAIL-");
        return 0;
    }
    return 1;
}

/* ---------- appendBytes ---------- */

ydb_long_t stdfs_appendBytes(ydb_string_t *path, ydb_string_t *data) {
    char pathbuf[STDFS_PATH_MAX];
    int fd;

    clear_err();
    if (copy_path(path, pathbuf) != 0) return 0;

    /* O_APPEND guarantees atomic positioning at EOF for each write(2) — no
     * lseek race even under concurrent appenders. */
    fd = open(pathbuf, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd < 0) {
        set_err_errno(",U-STDFS-OPEN-FAIL-");
        return 0;
    }

    if (data && data->address && data->length > 0) {
        if (write_all(fd, data->address, (size_t)data->length) != 0) {
            set_err_errno(",U-STDFS-WRITE-FAIL-");
            close(fd);
            return 0;
        }
    }

    if (close(fd) != 0) {
        set_err_errno(",U-STDFS-CLOSE-FAIL-");
        return 0;
    }
    return 1;
}

/* ---------- readBytes ---------- */

ydb_long_t stdfs_readBytes(ydb_string_t *path, ydb_string_t *out) {
    char pathbuf[STDFS_PATH_MAX];
    int fd;
    size_t off, cap;

    clear_err();
    if (!out || !out->address) {
        set_err(",U-STDFS-NULL-OUT,");
        return 0;
    }
    out->length = 0;
    if (copy_path(path, pathbuf) != 0) return 0;

    fd = open(pathbuf, O_RDONLY);
    if (fd < 0) {
        set_err_errno(",U-STDFS-OPEN-FAIL-");
        return 0;
    }

    cap = (size_t)out->length;          /* M-side preallocation budget. */
    if (cap == 0) cap = STDFS_OUT_BUFSIZE;
    off = 0;
    while (off < cap) {
        ssize_t r = read(fd, out->address + off, cap - off);
        if (r < 0) {
            if (errno == EINTR) continue;
            set_err_errno(",U-STDFS-READ-FAIL-");
            close(fd);
            return 0;
        }
        if (r == 0) break;              /* EOF. */
        off += (size_t)r;
    }

    /* If the caller's buffer filled before EOF, surface the truncation —
     * silent truncation would corrupt downstream consumers expecting
     * byte-faithful round-trip semantics. */
    if (off == cap) {
        char probe;
        ssize_t r = read(fd, &probe, 1);
        if (r > 0) {
            set_err(",U-STDFS-READ-TRUNCATED,");
            close(fd);
            return 0;
        }
    }

    close(fd);
    out->length = (unsigned int)off;
    return 1;
}

/* ---------- availability ---------- */

ydb_long_t stdfs_available(void) {
    /* Cheapest end-to-end check: open /dev/null O_RDONLY. If libc and the
     * kernel's open(2) syscall are reachable, we're wired. */
    int fd = open("/dev/null", O_RDONLY);
    if (fd < 0) return 0;
    close(fd);
    return 1;
}

/* ---------- last-error reader ---------- */

ydb_long_t stdfs_lasterror(ydb_string_t *out) {
    size_t n = strlen(g_lasterr);
    if (out == NULL || out->address == NULL) return 0;
    if (n > (size_t)out->length) n = (size_t)out->length;
    if (n > 0) memcpy(out->address, g_lasterr, n);
    out->length = (unsigned int)n;
    return 1;
}
