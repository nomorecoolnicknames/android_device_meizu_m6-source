/*
 * DIAGNOSTIC: Activity-backed Meizu M6 camera preview byte sampler.
 *
 * Runs with a real Android package identity so android.hardware.Camera.open()
 * passes a non-null op package name to the Oreo camera JNI.
 */

package org.androidforge.m6.camera.probe;

import android.app.Activity;
import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.SystemClock;
import android.util.Log;

import java.util.List;
import java.util.Locale;

public final class Camera1FrameProbeActivity extends Activity implements Camera.PreviewCallback {
    private static final String TAG = "M6CamFrameProbe";
    private static final int TARGET_FRAMES = 12;
    private static final long TIMEOUT_MS = 15000;

    private HandlerThread mThread;
    private Handler mHandler;
    private Camera mCamera;
    private SurfaceTexture mPreviewTexture;
    private int mWidth;
    private int mHeight;
    private int mFrameCount;
    private long mFirstFrameMs;
    private long mLastFrameMs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        final int cameraId = getIntent().getIntExtra("cameraId", 0);
        log("ACTIVITY_START cameraId=" + cameraId + " package=" + getPackageName()
                + " pid=" + android.os.Process.myPid());
        mThread = new HandlerThread("m6-camera1-probe");
        mThread.start();
        mHandler = new Handler(mThread.getLooper());
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                startCamera(cameraId);
            }
        });
        mHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (mFrameCount < TARGET_FRAMES) {
                    log("TIMEOUT frames=" + mFrameCount + " lastFrameMs=" + mLastFrameMs);
                    stopAndFinish();
                }
            }
        }, TIMEOUT_MS);
    }

    @Override
    protected void onDestroy() {
        stopCamera();
        if (mThread != null) {
            mThread.quitSafely();
            mThread = null;
        }
        super.onDestroy();
    }

    private void startCamera(int cameraId) {
        try {
            mCamera = Camera.open(cameraId);
            Camera.Parameters params = mCamera.getParameters();
            Camera.Size selected = selectPreviewSize(params.getSupportedPreviewSizes());
            if (selected != null) {
                params.setPreviewSize(selected.width, selected.height);
            }
            params.setPreviewFormat(ImageFormat.NV21);
            mCamera.setParameters(params);

            params = mCamera.getParameters();
            Camera.Size active = params.getPreviewSize();
            mWidth = active.width;
            mHeight = active.height;
            int format = params.getPreviewFormat();
            int bitsPerPixel = ImageFormat.getBitsPerPixel(format);
            int bufferSize = Math.max(1, mWidth * mHeight * bitsPerPixel / 8);
            log("CONFIG width=" + mWidth + " height=" + mHeight + " format=0x"
                    + Integer.toHexString(format) + " bitsPerPixel=" + bitsPerPixel
                    + " bufferSize=" + bufferSize);

            mPreviewTexture = new SurfaceTexture(0);
            mCamera.setPreviewTexture(mPreviewTexture);
            for (int i = 0; i < 4; i++) {
                mCamera.addCallbackBuffer(new byte[bufferSize]);
            }
            mCamera.setPreviewCallbackWithBuffer(this);
            mCamera.startPreview();
            log("PREVIEW_STARTED");
        } catch (Throwable t) {
            log("START_ERROR " + t);
            stopAndFinish();
        }
    }

    @Override
    public void onPreviewFrame(byte[] data, Camera camera) {
        long now = SystemClock.elapsedRealtime();
        if (mFrameCount == 0) {
            mFirstFrameMs = now;
        }
        mLastFrameMs = now;
        mFrameCount++;
        log(sampleFrame(data, mFrameCount, now - mFirstFrameMs));
        if (mFrameCount < TARGET_FRAMES) {
            camera.addCallbackBuffer(data);
            return;
        }
        stopAndFinish();
    }

    private String sampleFrame(byte[] data, int frame, long ageMs) {
        int ySize = Math.min(data.length, mWidth * mHeight);
        int samples = Math.min(8192, Math.max(1, ySize));
        int step = Math.max(1, ySize / samples);
        int minY = 255;
        int maxY = 0;
        int nonBlack = 0;
        long sumY = 0;
        int seen = 0;
        for (int offset = 0; offset < ySize && seen < samples; offset += step) {
            int y = data[offset] & 0xff;
            minY = Math.min(minY, y);
            maxY = Math.max(maxY, y);
            sumY += y;
            if (y > 8) {
                nonBlack++;
            }
            seen++;
        }
        int centerOffset = Math.min(ySize - 1, Math.max(0, (mHeight / 2) * mWidth + (mWidth / 2)));
        int centerY = data[centerOffset] & 0xff;
        StringBuilder first16 = new StringBuilder();
        for (int i = 0; i < Math.min(16, data.length); i++) {
            if (i > 0) {
                first16.append(',');
            }
            first16.append(String.format(Locale.US, "%02x", data[i] & 0xff));
        }
        return "FRAME frame=" + frame + " ageMs=" + ageMs + " bytes=" + data.length
                + " ySize=" + ySize + " samples=" + seen + " minY=" + minY
                + " maxY=" + maxY + " meanY=" + (seen > 0 ? (sumY / seen) : 0)
                + " centerY=" + centerY + " nonBlack=" + nonBlack
                + " first16=" + first16;
    }

    private void stopAndFinish() {
        stopCamera();
        log("DONE frames=" + mFrameCount);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                finish();
            }
        });
    }

    private synchronized void stopCamera() {
        try {
            if (mCamera != null) {
                mCamera.setPreviewCallbackWithBuffer(null);
                mCamera.stopPreview();
                mCamera.release();
                mCamera = null;
            }
        } catch (RuntimeException e) {
            log("STOP_ERROR " + e);
        }
        if (mPreviewTexture != null) {
            mPreviewTexture.release();
            mPreviewTexture = null;
        }
    }

    private static Camera.Size selectPreviewSize(List<Camera.Size> sizes) {
        if (sizes == null || sizes.isEmpty()) {
            return null;
        }
        Camera.Size best = sizes.get(0);
        for (Camera.Size size : sizes) {
            if (size.width == 1280 && size.height == 720) {
                return size;
            }
            if (size.width * size.height > best.width * best.height) {
                best = size;
            }
        }
        return best;
    }

    private static void log(String message) {
        Log.w(TAG, "M6_CAMERA1_FRAME_PROBE " + message);
    }
}
