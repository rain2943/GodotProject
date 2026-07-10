# GodotProject

Minimal Godot 4 project with automatic Windows and Web exports.

## Local development

1. Install Godot 4.5.1 or a compatible Godot 4 release.
2. Open this folder in Godot.
3. Run the project with F6/F5.

## Automatic build

Pushing to `main` starts `.github/workflows/build.yml`.

The workflow:

- validates the project in headless mode;
- exports a Windows build;
- exports a Web build;
- stores both builds as workflow artifacts;
- deploys the Web build to GitHub Pages.

After enabling GitHub Pages with `GitHub Actions` as the source in repository settings, the workflow will publish the phone-test URL after each successful push.
