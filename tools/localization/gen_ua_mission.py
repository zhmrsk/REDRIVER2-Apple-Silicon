# -*- coding: utf-8 -*-
import codecs

# Translation Map for Mission Text
translation_map = {
    "Chicago": "Чикаго",
    "Havana": "Гавана",
    "Las Vegas": "Лас Вегас",
    "Rio De Janeiro": "Ріо де Жанейро",
    "Surveillance tip off": "Наводка стеження",
    "Chase the witness": "Переслідування свідка",
    "Train pursuit": "Погоня за поїздом",
    "Tailing the drop": "Стеження за вантажем",
    "Escape to the safe house": "Втеча в притулок",
    "Chase the intruder": "Погоня за порушником",
    "Caine's compound": "База Кейна",
    "Leaving Chicago": "Покидаючи Чикаго",
    "Follow up the lead": "Слідувати за зачіпкою",
    "Hijack the truck": "Викрадення вантажівки",
    "Stop the truck": "Зупинити вантажівку",
    "Find the clue": "Знайти доказ",
    "Escape to ferry": "Втеча на паром",
    "To the docks": "В доки",
    "Back to Jones": "Назад до Джонса",
    "Tail Jericho": "Стеження за Джеріко",
    "Pursue Jericho": "Переслідування Джеріко",
    "Escape the Brazilians": "Втеча від Бразильців",
    "Casino Getaway": "Втеча з казино",
    "Beat the train": "Обігнати поїзд",
    "Car bomb": "Автобомба",
    "Car bomb getaway": "Втеча на замінованому авто",
    "Bank job": "Пограбування банку",
    "Steal the ambulance": "Викрасти швидку",
    "Stake Out": "Засідка",
    "Steal the keys": "Викрасти ключі",
    "C4 deal": "Угода з C4",
    "Destroy the yard": "Знищити двір",
    "Bus Crush": "Автобусний погром",
    "Steal the cop car": "Викрасти копінську тачку",
    "Caine's cash": "Готівка Кейна",
    "Save Jones": "Врятувати Джонса",
    "Boat jump": "Стрибок на човні",
    "Jones in trouble": "Джонс в біді",
    "Chase the Gun Man": "Погоня за стрілком",
    "Lenny escaping": "Ленні тікає",
    "Lenny gets caught": "Ленні спіймали",
    "Red River": "Ред Рівер",
    "The morgue": "Морг",
    "The Witness": "Свідок",
    "Lenny's apartment": "Квартира Ленні",
    "The Cuba Connection": "Кубинський зв'язок",
    "The Intruder": "Порушник",
    "Meeting Caine": "Зустріч з Кейном",
    "Leaving Town": "Покидаючи місто",
    "Looking for a lead": "Пошук зачіпки",
    "Moving out": "Виїзд",
    "Watching the truck": "Спостереження за вантажівкою",
    "Rosanna Soto Clue": "Зачіпка Розанни Сото",
    "The Dockyard": "Верф",
    "The Hit": "Замовлення",
    "Seizing Jericho": "Затримання Джеріко",
    "Vasquez in Vegas": "Васкез в Вегасі",
    "Trading Jericho": "Обмін Джеріко",
    "The Pool Hall": "Більярдна",
    "Caine's Warpath": "Стежка війни Кейна",
    "Caine in Rio": "Кейн в Ріо",
    "Warning Jones": "Попередження Джонса",
    "The Shootout": "Перестрілка",
    "Lenny's getaway": "Втеча Ленні",
    "Lenny gets it": "Ленні отримує своє",
    "Back in Chicago": "Знову в Чикаго",
    "Vasquez meets Caine": "Васкез зустрічає Кейна",
    "The End": "Кінець",
    "Downtown": "Центр",
    "Wrigleyville": "Ріглівідь",
    "Greektown": "Гріктаун",
    "Grant Park": "Грант Парк",
    "Meigs Field": "Мейгс Філд",
    "Ukrainian Village": "Українське село",
    "River North": "Рівер Норт",
    "Cabrini Green": "Кабріні Грін",
    "Necropolis de Colon": "Некрополь де Колон",
    "Capitolio": "Капітолій",
    "Old Havana": "Стара Гавана",
    "The Docks": "Доки",
    "Vedado": "Ведадо",
    "Plaza": "Площа",
    "Plaza de la Revolucion": "Площа Революції",
    "Upper Strip": "Аппер Стріп",
    "Lakeside": "Лейксайд",
    "Mid Strip": "Мід Стріп",
    "North Vegas": "Північний Вегас",
    "Lakes": "Озера",
    "Ghost Town": "Місто Привид",
    "Centro": "Центро",
    "Copacabana": "Копакабана",
    "Santa Tereza": "Санта Тереза",
    "Lagoa Rodrigo de Freitas": "Лагуна Родріго",
    "Praca da Bandeira": "Праса да Бандейра",
    "Leblon": "Леблон",
    "Flamengo": "Фламенго"
}

def translate_file(input_path, output_path):
    with open(input_path, 'r', encoding='utf-8') as f_in:
        lines = f_in.readlines()
    
    with codecs.open(output_path, 'w', 'cp1251') as f_out:
        for i, line in enumerate(lines):
            original = line.strip()
            translated = translation_map.get(original)
            
            if not translated:
                print(f"Warning: No translation for line {i+1}: '{original}'")
                translated = original 
            
            f_out.write(translated + '\r\n')

if __name__ == "__main__":
    translate_file("github_assets/DRIVER2/LANG/EN_MISSION.LTXT", "github_assets/DRIVER2/LANG/UA_MISSION.LTXT")
    print("UA_MISSION.LTXT generated.")
