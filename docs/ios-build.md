
## TestFlight workflow

`.github/workflows/ios-testflight.yml` is a separate signed-build workflow. It runs manually or when an `ios-v*` tag is pushed, signs the app with an Apple Distribution certificate, exports an App Store IPA, uploads the IPA artifact, and submits it to TestFlight.

Configure these GitHub Actions secrets before running it:

- `IOS_DISTRIBUTION_CERTIFICATE_BASE64`: base64-encoded `.p12` Apple Distribution certificate.
- `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`: password for that `.p12` file.
- `IOS_PROVISIONING_PROFILE_BASE64`: base64-encoded App Store provisioning profile for `com.synapselabs.kryptaudio`.
- `IOS_TEAM_ID`: Apple Developer Team ID.
- `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect API issuer ID.
- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API key ID.
- `APP_STORE_CONNECT_API_PRIVATE_KEY`: the complete multiline `.p8` private-key contents.

Create the certificate and provisioning profile in the Apple Developer portal, and create the App Store Connect API key in App Store Connect. Store them only as GitHub Actions secrets; do not commit `.p12`, `.mobileprovision`, `.p8`, passwords, or Apple account credentials to the repository.

To run it manually, open **Actions → Build and upload KRYPT AUDIO to TestFlight → Run workflow**. To trigger it from Git, push a tag such as `ios-v2.2.4`. The workflow requires the repository's Apple bundle ID to match `com.synapselabs.kryptaudio`.

A normal Apple ID login or 2FA code is not needed in the workflow. TestFlight upload uses the App Store Connect API key, while code signing uses the certificate and provisioning profile secrets.
