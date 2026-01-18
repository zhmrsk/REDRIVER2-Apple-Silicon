# Localization Tools

Scripts for creating and managing game localizations for REDRIVER2.

## Ukrainian Localization

These scripts were used to create the Ukrainian localization included in this fork.

### Scripts

#### `gen_full_ua.py`
Generates full Ukrainian localization by combining menu text, subtitles, and mission comments.

#### `gen_ua_mission.py`
Generates Ukrainian mission briefing files (`.D2MS`).

#### `gen_ua_strings.py`
Generates Ukrainian menu text files (`.LTXT`).

#### `localize_missions.py`
Processes mission files and adds localized text.

#### `localize_sbn.py`
Processes subtitle files (`.SBN`) and adds localized text.

#### `localize_all_missions.py`
Batch processes all missions for localization.

#### `translate_all_languages.py`
Multi-language translation tool supporting multiple target languages.

## Usage

### Prerequisites
- Python 3.6+
- Original Driver 2 game files extracted

### Creating a New Localization

1. Extract game files from original discs
2. Prepare translation files (text format)
3. Run appropriate scripts to generate localized files
4. Place generated files in `data/DRIVER2/LANG/` and `data/DRIVER2/MISSIONS/`

### File Formats

#### Language Files (`.LTXT`)
Menu text and UI strings.

#### Subtitle Files (`.SBN`)
In-game cutscene subtitles.

#### Mission Files (`.D2MS`)
Mission briefings and objectives.

## Contributing

To add a new language:
1. Create translation files
2. Modify scripts to support your language code
3. Test thoroughly
4. Submit a pull request

## Credits

Ukrainian localization created by [Your Name].
