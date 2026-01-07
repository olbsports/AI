# Configuration des Permissions pour les Photos

## Android

Ajoutez les permissions suivantes dans
`/home/user/AI/apps/mobile/android/app/src/main/AndroidManifest.xml` :

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions pour les photos -->
    <!-- Android 13+ (API 33+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

    <!-- Android 12 et inférieur -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />

    <application>
        <!-- Votre configuration existante -->
    </application>
</manifest>
```

## iOS

Ajoutez les clés suivantes dans
`/home/user/AI/apps/mobile/ios/Runner/Info.plist` :

```xml
<dict>
    <!-- Votre configuration existante -->

    <!-- Permissions pour les photos -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Nous avons besoin d'accéder à vos photos pour ajouter des photos de profil de vos chevaux et cavaliers.</string>

    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Nous avons besoin d'accéder à vos photos pour sauvegarder des images.</string>
</dict>
```

## Test après configuration

1. Installez les dépendances :

   ```bash
   cd /home/user/AI/apps/mobile
   flutter pub get
   ```

2. Analysez le code :

   ```bash
   flutter analyze
   ```

3. Testez sur un appareil réel :
   ```bash
   flutter run
   ```

## Notes importantes

- **Android 13+** : Utilise la permission `READ_MEDIA_IMAGES` au lieu de
  `READ_EXTERNAL_STORAGE`
- **iOS** : Les descriptions de permissions sont obligatoires et seront
  affichées à l'utilisateur
- Le code gère automatiquement le fallback entre les permissions selon la
  version Android
- Si l'utilisateur refuse de manière permanente, une boîte de dialogue propose
  d'ouvrir les paramètres
