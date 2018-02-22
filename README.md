# Cordova Plugin Protocol

Allows the creation of a custom protocol to serve files locally without using the file scheme.

## Usage

Once the plugin installed, change the content location in your `config.xml`:

```xml
<content src="scheme-plugin://<anything>/index.html" />
```

The host location can be anything as it is ignored while serving files locally, you just need to respect a url format.


To allow the scheme to be used, you will also need to add this configuration for the `cordova-plugin-whitelist`:

```xml
<allow-navigation href="scheme-plugin://*/*" />
```

This will by default serve the files located in your `www` directory. You can change this by setting `Root` in the preferences:

```xml
<preference name="Root" value="<your root directory>"/>
```

You can also choose a different scheme by setting the `Scheme` preference:

```xml
<preference name="Scheme" value="<your scheme>"/>
```

If you do so, you will have to update the `content`, and `allow-navigation` directives too.
