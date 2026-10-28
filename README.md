# Mega Merge Monsters (Мега Мердж Монстры)

Казуальная 2D физическая головоломка в жанре слияния (Merge / Suika style), разработанная на Godot 4 для платформы **Яндекс Игры**.

---

## Материалы для консоли Яндекс Игр (Русский язык)

### Короткое описание (до 70 символов)
> **Символов: 63 / 70**
```text
Сбрасывайте и объединяйте забавных монстров, создавая гигантов!
```

---

### Описание для SEO (до 160 символов)
> **Символов: 144 / 160**
```text
Увлекательная физическая головоломка со слиянием монстров в котле! Делайте комбо, открывайте гигантских существ и побеждайте в таблице лидеров.
```

---

### Об игре (до 1000 символов)
> **Символов: 874 / 1000**
```text
«Мега Мердж Монстры» — это залипательная казуальная головоломка с сочной физикой в стиле популярного жанра слияния!

Ваша задача — сбрасывать забавных монстриков в магический котёл. Когда два одинаковых существа соприкасаются, они объединяются в нового, более крупного и ценного монстра. Пройдите эволюционную цепочку из 15 уникальных существ и создайте легендарного титана!

Особенности игры:
• Живая физика и яркие спецэффекты слияний.
• Система комбо: объединяйте монстров быстро и умножайте полученные очки.
• Магазин улучшений: увеличивайте доход монет, расширяйте окно комбо и получайте запасные жизни.
• Спасительная бомба: очищайте заторы в котле в критический момент.
• Второе дыхание: возможность продолжить партию после переполнения котла.
• Общая таблица лидеров: соревнуйтесь с другими игроками за звание лучшего монстроведа!

Игра отлично подходит для отдыха и снятия стресса как на компьютере, так и на смартфонах.
```

---

### Как играть (до 1000 символов)
> **Символов: 914 / 1000**
```text
Цель игры — объединять одинаковых монстров и набрать рекордный счёт, не позволяя котлу переполниться выше красной линии.

Управление на ПК:
• Движение мыши — выбор позиции для сброса монстра.
• Левая кнопка мыши (ЛКМ) или Пробел — сбросить монстра в котёл.
• Кнопка бомбы вверху экрана — использовать бомбу для взрыва мешающих существ.

Управление на смартфонах и планшетах:
• Касание и ведение пальцем по экрану — прицеливание.
• Отпускание пальца — сброс монстра в котёл.
• Нажатие на значок бомбы — активация взрыва.

Полезные советы:
• Соединяйте одинаковых монстров рядом, чтобы освобождать место для новых.
• Удерживайте комбо: чем быстрее происходят слияния, тем больше очков вы зарабатываете.
• Зарабатывайте монеты и улучшайте навыки в магазине: увеличивайте таймер комбо, доход монет и покупайте бомбы.
• Если котёл заполнился до краёв, используйте дополнительную жизнь или посмотрите рекламу, чтобы спасти партию!
```

---

## Yandex Games Console Materials (English)

### Short Description (up to 70 characters)
> **Characters: 68 / 70**
```text
Drop and merge cute monsters in the cauldron to create giant titans!
```

---

### SEO Description (up to 160 characters)
> **Characters: 149 / 160**
```text
Addictive physics merge puzzle! Drop monsters into the magic cauldron, create epic combos, evolve 15 unique creatures, and dominate the leaderboard.
```

---

### About the Game (up to 1000 characters)
> **Characters: 893 / 1000**
```text
Mega Merge Monsters is an addictive casual physics puzzle in the popular merge style!

Your goal is to drop charming monsters into a magical cauldron. When two identical creatures touch, they merge into a larger, more advanced monster. Evolve through 15 unique levels to summon the ultimate mythical titan!

Game Features:
• Juicy physics and satisfying merge visual effects.
• Dynamic Combo System: chain rapid merges to multiply your score exponentially.
• Upgrade Shop: boost coin earnings, extend combo duration, and buy extra lives.
• Panic Button (Bomb): blast away clutter and junk monsters when space runs out.
• Revive Mechanic: clear smaller monsters and keep your run alive after an overflow.
• Global Leaderboard: compete with players worldwide for the highest score!

A relaxing yet engaging anti-stress game designed for both mobile touchscreens and desktop browsers.
```

---

### How to Play (up to 1000 characters)
> **Characters: 919 / 1000**
```text
Goal: Merge identical monsters to grow larger ones and score points without overflowing past the red danger line.

Controls on PC:
• Move Mouse — aim drop position horizontally.
• Left Click (LMB) or Spacebar — drop monster into the cauldron.
• Click the Bomb button — detonate a bomb to clear crowded areas.

Controls on Mobile / Tablets:
• Touch & Drag across the screen — aim.
• Release finger — drop monster.
• Tap the Bomb icon — trigger explosion.

Helpful Tips:
• Plan ahead and keep similar-tier monsters close to each other.
• Keep the combo chain active: quick consecutive merges grant massive score multipliers.
• Spend earned coins in the Upgrades menu to increase combo duration, boost coin rewards, and restock bombs.
• If the cauldron overflows, use an Extra Life or watch a rewarded video to clear small monsters and continue your record run!
```

---

## Техническая справка по сборке (Web Export)

1. **Экспорт из Godot:**
   - Открыть Godot: **Проект → Экспорт → Web**.
   - Нажать **«Экспортировать проект...»** (не ZIP!).
   - Сохранить в папку `export_web` с именем файла `index.html`.

2. **Создание архива для консоли Яндекс Игр:**
   - В терминале выполнить скрипт:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\package_yandex.ps1
     ```
   - Скрипт скопирует `yandex_sdk_bridge.js` в корень сборки и создаст архив `yandex_build.zip`.
   - Загрузить `yandex_build.zip` в Консоль разработчика Яндекс Игр на вкладку «Черновик».
