TODO: 


Android setup :

Go to the build.gradle file for your Android app to specify the custom scheme so that there should be a section in it that look similar to the following but replace <your_custom_scheme> with the desired value

...
android {
    ...
    defaultConfig {
        ...
        manifestPlaceholders += [
                'appAuthRedirectScheme': '<your_custom_scheme>'
        ]
    }
}


TODO:

iOS/macOS setup :
Go to the Info.plist for your iOS/macOS app to specify the custom scheme so that there should be a section in it that look similar to the following but replace <your_custom_scheme> with the desired value

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string><your_custom_scheme></string>
        </array>
    </dict>
</array>





WEB :
TODO :
add script into index.html file , in web folder into flutter project

  <script>
    window.opener.postMessage(window.location.href, '*');
  </script>



TODO : create new file auth.html , and put it in the web folder for flutter project

<!DOCTYPE html>
<title>Authentication complete</title>
<p>Authentication is complete. If this does not happen automatically, please
close the window.
<script>
  window.opener.postMessage({
    'flutter-web-auth': window.location.href
  }, window.location.origin);
  window.close();
</script>