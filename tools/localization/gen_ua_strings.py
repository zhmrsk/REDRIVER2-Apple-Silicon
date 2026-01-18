# -*- coding: utf-8 -*-
import codecs

strings_ua = [
    "Чикаго", "Гавана", "Вегас", "Ріо",
    "Нова Гра", "Завантажити Гру", "Переграти Місію", "Перегляд Роликів",
    "Завантажити Повтор", "Показати Погоню 1", "Показати Погоню 2", "Показати Погоню 3", "Показати Погоню 4",
    "Швидка Погоня", "Швидка Втеча", "Перегони", "Першопроходець", "Чекпоінт", "Виживання", "Копи та Грабіжники", "Захоплення Прапора",
    "Гра 1", "Гра 2",
    "Недоступно",
    "Використовуйте стрілки", "Для переміщення",
    "Звук", "Геймплей", "Центрування", "Зберегти Налаштування", "Завантажити Налаштування",
    "Попередній", "Вибрати", "Наступний", "Виберіть Авто",
    "Складність Копів", "Субтитри", "Вібрація", "Контролер",
    "Легко", "Середньо", "Важко",
    "Увімк", "Вимк",
    "Наводка стеження", "Авто Тестування", "Ленні спіймали",
    "Режисерська версія", "Виберіть Ролик",
    "Ефекти", "Музика", "Гучність",
    "Однокористувацька", "Мультиплеєр",
    "Гірський Перевал", "Гоночний Трек",
    "Рівер Норт", "Кабріні Грін", "Площа Революції", "Стара Гавана", "Центр", "Озера", "Центро", "Фламенго"
]

strings_en = [
    "Chicago", "Havana", "Vegas", "Rio",
    "New Game", "Load Game", "Replay Mission", "View Cutscenes",
    "Load Replay", "Show Chase 1", "Show Chase 2", "Show Chase 3", "Show Chase 4",
    "Quick Chase", "Quick Getaway", "Gate Racing", "Trailblazer", "Checkpoint", "Survival", "Cops 'n' Robbers", "Capture the Flag",
    "Game 1", "Game 2",
    "Not Available",
    "Use directional buttons", "To Move Screen",
    "Sound", "Gameplay", "Center Screen", "Save Settings", "Load Settings",
    "Previous", "Select", "Next", "Choose A Ride",
    "Cop Difficulty", "Subtitles", "Vibration", "Controller",
    "Easy", "Medium", "Hard",
    "On", "Off",
    "Surveillance tip off", "Auto Testing", "Lenny gets caught",
    "Director's Cut", "Choose A Cutscene",
    "Sfx", "Music", "Set Volume Levels",
    "Single Player", "Multiplayer",
    "Mountain Pass", "Race Track",
    "River North", "Cabrini Green", "Plaza de Revolucion", "Old Havana", "Downtown", "The Lakes", "Centro", "Flamengo"
]

# base_path = "github_assets/DRIVER2/LANG/"
base_path = "src_rebuild/bin/Release_dev/REDRIVER2.app/Contents/Resources/data/DRIVER2/LANG/"

def append_strings(filename, strings, encoding):
    with codecs.open(filename, "a", encoding) as f:
        for s in strings:
            f.write(s + "\n")

if __name__ == "__main__":
    # Remove existing additions if script run multiple times?
    # No, we assume clean state or user management.
    
    # Append to UA_GAME.LTXT (CP1251)
    # Using 'cp1251' encoding for writing
    # Ensure dir exists (it should after build)
    
    with open(base_path + "UA_GAME.LTXT", "ab") as f:
        for s in strings_ua:
            # Encode string to CP1251 bytes
            encoded = s.encode('cp1251')
            f.write(encoded + b'\r\n') # CRLF for windows compatibility usually

    # Append to EN_GAME.LTXT (ASCII/Default)
    # DISABLED to ensure English integrity
    # with open(base_path + "EN_GAME.LTXT", "a") as f:
    #     for s in strings_en:
    #         f.write(s + "\n")
            
    print("Strings appended.")
