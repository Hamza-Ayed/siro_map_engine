package com.siro.gl;

import java.util.concurrent.atomic.AtomicLong;
import okhttp3.Interceptor;
import okhttp3.Response;

/**
 * Counts the requests and response bytes of every OkHttp client the plugin builds. Counting is off
 * until {@link #setEnabled(boolean)} is called.
 *
 * <p>Bytes come from Content-Length, so a chunked response adds nothing to the total.
 */
final class SiroNetworkStats {
  private static volatile boolean enabled = false;
  private static final AtomicLong requests = new AtomicLong();
  private static final AtomicLong bytes = new AtomicLong();

  static final Interceptor INTERCEPTOR =
      chain -> {
        if (!enabled) {
          return chain.proceed(chain.request());
        }
        requests.incrementAndGet();
        Response response = chain.proceed(chain.request());
        if (response.body() != null) {
          long length = response.body().contentLength();
          if (length > 0) {
            bytes.addAndGet(length);
          }
        }
        return response;
      };

  private SiroNetworkStats() {}

  static void setEnabled(boolean value) {
    enabled = value;
  }

  static void reset() {
    requests.set(0);
    bytes.set(0);
  }

  static long requestCount() {
    return requests.get();
  }

  static long byteCount() {
    return bytes.get();
  }
}
