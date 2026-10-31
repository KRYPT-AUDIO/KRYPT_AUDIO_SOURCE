from __future__ import annotations

import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "plugins"
TMP = ROOT / ".official-plugin-build"
ORG = "https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE"
RAW = "https://raw.githubusercontent.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/main"
AUTHOR = "Synapse Labs UK Ltd"

PLUGINS = [
    ("neon-glass", "Neon Glass", "Futuristic purple-and-blue Liquid Glass surfaces with glowing accents and ambient depth.", "theme", {
        "--krypt-background": "#080611", "--krypt-surface": "rgba(29, 18, 58, .72)", "--krypt-surface-strong": "rgba(50, 29, 93, .86)", "--krypt-primary": "#b36cff", "--krypt-secondary": "#4ac8ff", "--krypt-glow": "#8f4dff", "--krypt-radius": "24px", "--krypt-motion": "smooth"
    }),
    ("amoled-black", "AMOLED Black", "Pure-black AMOLED theme with vibrant purple highlights and minimal visual distraction.", "theme", {
        "--krypt-background": "#000000", "--krypt-surface": "#050505", "--krypt-surface-strong": "#101010", "--krypt-primary": "#c084fc", "--krypt-secondary": "#7c3aed", "--krypt-glow": "#6d28d9", "--krypt-radius": "14px", "--krypt-motion": "reduced"
    }),
    ("cyberpunk-2077", "Cyberpunk 2077", "Neon cyberpunk palette with high-tech borders, electric yellow and magenta highlights.", "theme", {
        "--krypt-background": "#090b12", "--krypt-surface": "rgba(20, 25, 36, .9)", "--krypt-surface-strong": "#151b26", "--krypt-primary": "#fcee0a", "--krypt-secondary": "#ff2a9b", "--krypt-glow": "#00e5ff", "--krypt-radius": "8px", "--krypt-border": "#00e5ff"
    }),
    ("visualizer-pro", "Visualizer Pro", "Music-reactive visualizer preset with spectrum bars, waveform styling and beat-synced motion tokens.", "visualizer", {
        "--krypt-background": "#070913", "--krypt-surface": "rgba(15, 22, 44, .82)", "--krypt-surface-strong": "#15204a", "--krypt-primary": "#4dd8ff", "--krypt-secondary": "#a855f7", "--krypt-glow": "#2563eb", "--krypt-visualizer-bars": "64", "--krypt-visualizer-mode": "spectrum"
    }),
    ("lyrics-plus", "Lyrics Plus", "Enhanced lyrics typography, active-line highlighting and synchronized presentation preset.", "lyrics", {
        "--krypt-background": "#0b0b12", "--krypt-surface": "rgba(28, 25, 48, .8)", "--krypt-surface-strong": "#272044", "--krypt-primary": "#e9b8ff", "--krypt-secondary": "#8be9fd", "--krypt-glow": "#c026d3", "--krypt-lyrics-size": "1.16em", "--krypt-lyrics-active": "#ffffff"
    }),
    ("basshead", "Basshead", "Dark bass-driven styling with pulsing accents, aggressive contrast and heavy music energy.", "theme", {
        "--krypt-background": "#070707", "--krypt-surface": "#151015", "--krypt-surface-strong": "#241324", "--krypt-primary": "#ff3d81", "--krypt-secondary": "#ff8a00", "--krypt-glow": "#e11d48", "--krypt-radius": "10px", "--krypt-beat-pulse": "enabled"
    }),
    ("midnight-blue", "Midnight Blue", "Clean midnight-blue interface with electric-blue highlights and elegant gradients.", "theme", {
        "--krypt-background": "#06111f", "--krypt-surface": "rgba(12, 31, 57, .82)", "--krypt-surface-strong": "#12345c", "--krypt-primary": "#55b7ff", "--krypt-secondary": "#7dd3fc", "--krypt-glow": "#2563eb", "--krypt-radius": "18px"
    }),
    ("minimal-player", "Minimal Player", "Distraction-free player preset focused on album artwork, progress and essential controls.", "player", {
        "--krypt-background": "#0a0a0a", "--krypt-surface": "rgba(22, 22, 22, .92)", "--krypt-surface-strong": "#202020", "--krypt-primary": "#f5f5f5", "--krypt-secondary": "#a3a3a3", "--krypt-glow": "transparent", "--krypt-player-density": "minimal", "--krypt-radius": "20px"
    }),
    ("album-art-glow", "Album Art Glow", "Dynamic ambient-colour preset driven by the currently playing album artwork.", "player", {
        "--krypt-background": "#08080d", "--krypt-surface": "rgba(24, 24, 35, .72)", "--krypt-surface-strong": "rgba(42, 42, 62, .82)", "--krypt-primary": "var(--album-art-primary, #c084fc)", "--krypt-secondary": "var(--album-art-secondary, #38bdf8)", "--krypt-glow": "var(--album-art-glow, #8b5cf6)", "--krypt-art-glow": "enabled"
    }),
    ("retro-wave", "Retro Wave", "Synthwave-inspired neon pinks, purple gradients and 80s visual energy.", "theme", {
        "--krypt-background": "#12051d", "--krypt-surface": "rgba(43, 10, 68, .8)", "--krypt-surface-strong": "#5b176e", "--krypt-primary": "#ff4fd8", "--krypt-secondary": "#7c5cff", "--krypt-glow": "#ff1fb3", "--krypt-radius": "12px", "--krypt-grid-lines": "enabled"
    }),
    ("listening-stats-plus", "Listening Stats Plus", "Listening statistics preset with breakdown cards, trend visuals and chart-ready colour tokens.", "stats", {
        "--krypt-background": "#090b14", "--krypt-surface": "rgba(22, 27, 49, .8)", "--krypt-surface-strong": "#1d2a52", "--krypt-primary": "#a78bfa", "--krypt-secondary": "#34d399", "--krypt-glow": "#6366f1", "--krypt-stats-density": "detailed", "--krypt-chart-grid": "#27335c"
    }),
    ("playlist-studio", "Playlist Studio", "Playlist organisation preset with artwork-forward cards, colour labels and customisation tokens.", "playlists", {
        "--krypt-background": "#0a0c10", "--krypt-surface": "rgba(25, 30, 40, .84)", "--krypt-surface-strong": "#273244", "--krypt-primary": "#fbbf24", "--krypt-secondary": "#fb7185", "--krypt-glow": "#f59e0b", "--krypt-playlist-labels": "enabled", "--krypt-playlist-art": "large"
    }),
    ("smooth-transitions", "Smooth Transitions", "Enhanced transition timing and easing preset for tracks, screens and player states.", "motion", {
        "--krypt-background": "#08090d", "--krypt-surface": "rgba(26, 27, 38, .8)", "--krypt-surface-strong": "#303246", "--krypt-primary": "#c4b5fd", "--krypt-secondary": "#67e8f9", "--krypt-glow": "#8b5cf6", "--krypt-transition-duration": "420ms", "--krypt-transition-easing": "cubic-bezier(.22, 1, .36, 1)"
    }),
    ("glass-everywhere", "Glass Everywhere", "Consistent translucent glass treatment across supported cards, menus and interface surfaces.", "theme", {
        "--krypt-background": "#070711", "--krypt-surface": "rgba(255, 255, 255, .08)", "--krypt-surface-strong": "rgba(255, 255, 255, .14)", "--krypt-primary": "#d8b4fe", "--krypt-secondary": "#7dd3fc", "--krypt-glow": "#8b5cf6", "--krypt-glass-blur": "24px", "--krypt-radius": "22px"
    }),
    ("krypt-essentials", "KRYPT Essentials", "Small interface refinements and quality-of-life defaults bundled into one official preset.", "quality-of-life", {
        "--krypt-background": "#09090f", "--krypt-surface": "rgba(27, 25, 43, .78)", "--krypt-surface-strong": "#302b4c", "--krypt-primary": "#b794f4", "--krypt-secondary": "#60a5fa", "--krypt-glow": "#7c3aed", "--krypt-radius": "18px", "--krypt-motion": "smooth", "--krypt-focus-ring": "enabled"
    }),
]


def js_for(plugin_id: str, capability: str) -> str:
    return f'''// KRYPT AUDIO official plugin: {plugin_id}\n// GPL-3.0. This file is a declarative hook manifest for the safe plugin runtime.\n// Downloaded JavaScript is stored and validated by the app but is not executed\n// with unrestricted native access. CSS tokens are applied by KryptPluginService.\nexport default {{\n  id: '{plugin_id}',\n  capability: '{capability}',\n  onEnable(api) {{ api.log('Enabled {plugin_id}'); }},\n  onDisable(api) {{ api.log('Disabled {plugin_id}'); }}\n}};\n'''


def css_for(tokens: dict[str, str]) -> str:
    body = '\n'.join(f'  {key}: {value};' for key, value in tokens.items())
    return f'''/* KRYPT AUDIO official plugin theme tokens. GPL-3.0. */\n:root {{\n{body}\n}}\n'''


def main() -> None:
    if TMP.exists():
        shutil.rmtree(TMP)
    if OUT.exists():
        shutil.rmtree(OUT)
    (OUT / 'official').mkdir(parents=True)
    TMP.mkdir()
    catalog = []
    for plugin_id, name, description, capability, tokens in PLUGINS:
        version = '1.0.0'
        manifest = {
            'id': plugin_id,
            'name': name,
            'version': version,
            'description': description,
            'author': AUTHOR,
            'minAppVersion': '1.0.2',
            'entryScript': 'plugin.js',
            'stylesheet': 'theme.css',
            'permissions': ['theme', capability],
            'downloadUrl': f'{RAW}/plugins/official/{plugin_id}/{plugin_id}.kryptplugin',
            'repositoryUrl': f'{ORG}/tree/main/plugins/official/{plugin_id}',
        }
        work = TMP / plugin_id
        work.mkdir()
        (work / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        (work / 'plugin.js').write_text(js_for(plugin_id, capability))
        (work / 'theme.css').write_text(css_for(tokens))
        package_dir = OUT / 'official' / plugin_id
        package_dir.mkdir(parents=True)
        package = package_dir / f'{plugin_id}.kryptplugin'
        with zipfile.ZipFile(package, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
            for file in sorted(work.iterdir()):
                archive.write(file, file.name)
        catalog.append({**manifest, 'capability': capability, 'packageSizeBytes': package.stat().st_size})
    (OUT / 'index.json').write_text(json.dumps(catalog, indent=2) + '\n')
    shutil.rmtree(TMP)
    print(f'Generated {len(catalog)} official plugins')


if __name__ == '__main__':
    main()
