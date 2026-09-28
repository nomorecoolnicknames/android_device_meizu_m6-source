/*
 * DIAGNOSTIC: Meizu M6 camera bring-up helper.
 *
 * Build as a small app_process jar and run as shell/root on-device to sample
 * Camera1 preview callback bytes without rebuilding the ROM or Camera2 app.
 */

package org.androidforge.m6.camera;

import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;

import java.util.List;
import java.util.Locale;

public final class Camera1FrameProbe implements Camera.PreviewCallback {
    private static final String TAG = "M6CamFrameProbe";
    private static final int DEFAULT_CAMERA_ID = 0;
    private static final int TARGET_FRAMES = 12;
    private static final long TIMEOUT_MS = 15000;

    private Camera mCamera;
    private SurfaceTexture mPreviewTexture;
    private int mWidth;
    private int mHeight;
    private int mFormat;
    private int mFrameCount;
    private long mFirstFrameMs;
    private long mLastFrameMs;
    private Looper mLooper;

    public static void main(String[] args) throws Exception {
        int cameraId = DEFAULT_CAMERA_ID;
        if (args.length > 0) {
            cameraId = Integer.parseInt(args[0]);
        }

        Looper.prepare();
        Camera1FrameProbe probe = new Camera1FrameProbe();
        probe.mLooper = Looper.myLooper();
        probe.start(cameraId);
        Looper.loop();
    }

    private void start(int cameraId) throws Exception {
        log("START cameraId=" + cameraId + " pid=" + android.os.Process.myPid());
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
        mFormat = params.getPreviewFormat();
        int bitsPerPixel = ImageFormat.getBitsPerPixel(mFormat);
        int bufferSize = Math.max(1, mWidth * mHeight * bitsPerPixel / 8);
        log("CONFIG width=" + mWidth + " height=" + mHeight + " format=0x"
                + Integer.toHexString(mFormat) + " bitsPerPixel=" + bitsPerPixel
                + " bufferSize=" + bufferSize);

        mPreviewTexture = new SurfaceTexture(0);
        mCamera.setPreviewTexture(mPreviewTexture);
        for (int i = 0; i < 4; i++) {
            mCamera.addCallbackBuffer(new byte[bufferSize]);
        }
        mCamera.setPreviewCallbackWithBuffer(this);
        mCamera.startPreview();

        new Thread(new Runnable() {
            @Override
            public void run() {
                SystemClock.sleep(TIMEOUT_MS);
                if (mFrameCount < TARGET_FRAMES) {
                    log("TIMEOUT frames=" + mFrameCount + " lastFrameMs=" + mLastFrameMs);
                    stopAndQuit();
                }
            }
        }, "m6-camera1-probe-timeout").start();
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
        stopAndQuit();
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

    private synchronized void stopAndQuit() {
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
        log("DONE frames=" + mFrameCount);
        if (mLooper != null) {
            mLooper.quit();
        }
    }

    private static void log(String message) {
        String line = "M6_CAMERA1_FRAME_PROBE " + message;
        Log.w(TAG, line);
        System.out.println(line);
    }
}
