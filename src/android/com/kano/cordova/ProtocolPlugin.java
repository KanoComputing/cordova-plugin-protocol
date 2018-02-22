package com.kano.cordova;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaResourceApi;

import android.net.Uri;
import android.webkit.MimeTypeMap;
import android.content.res.AssetFileDescriptor;

import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import java.io.FileNotFoundException;

import android.app.Activity;
import android.content.res.AssetManager;

public class ProtocolPlugin extends CordovaPlugin  {

    private static String LOG_TAG = "ProtocolPlugin";
    private static AssetManager assetManager;
    private static Activity activity;
    private static String root;
    private static String scheme;
    
    public void pluginInitialize() {
        activity = cordova.getActivity();
        assetManager = activity.getAssets();
        root = preferences.getString("Root", "www");
        scheme = preferences.getString("Scheme", "protocol-plugin");
    }
    
    public Uri remapUri(Uri uri) {
        if (scheme.equals(uri.getScheme())) {
            return toPluginUri(uri);
        }
        return uri;
    }
    
    public CordovaResourceApi.OpenForReadResult handleOpenForRead(Uri pluginUri) throws IOException {
        Uri uri = fromPluginUri(pluginUri);
        String assetPath = root + uri.getPath();
        AssetFileDescriptor assetFd = null;
        InputStream inputStream;
        long length = -1;
        try {
            assetFd = assetManager.openFd(assetPath);
            inputStream = assetFd.createInputStream();
            length = assetFd.getLength();
        } catch (FileNotFoundException e) {
            // Will occur if the file is compressed.
            inputStream = assetManager.open(assetPath);
        }
        String mimeType = getMimeTypeFromPath(assetPath);
        return new CordovaResourceApi.OpenForReadResult(uri, inputStream, mimeType, length, assetFd);
    }

    private String getMimeTypeFromPath(String path) {
        String extension = path;
        int lastDot = extension.lastIndexOf('.');
        if (lastDot != -1) {
            extension = extension.substring(lastDot + 1);
        }
        // Convert the URI string to lower case to ensure compatibility with MimeTypeMap (see CB-2185).
        extension = extension.toLowerCase(Locale.getDefault());
        if (extension.equals("3ga")) {
            return "audio/3gpp";
        } else if (extension.equals("js")) {
            // Missing from the map :(.
            return "text/javascript";
        }
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
    }
}