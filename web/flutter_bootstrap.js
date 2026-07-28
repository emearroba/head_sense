{{flutter_js}}
{{flutter_build_config}}

const userConfig = {"canvasKitBaseUrl": "/canvaskit/","renderer": "canvaskit"};
_flutter.loader.load(
    {
        config: userConfig,
        onEntrypointLoaded: async function(engineInitializer) {
            // Initialize the Flutter engine
            let appRunner = await engineInitializer.initializeEngine({useColorEmoji: true,});
            // Run the app
            await appRunner.runApp();
          }
    }
);
