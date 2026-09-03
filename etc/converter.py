import os
import csv

def convert_csv_to_tsv(root_directory):
    """
    Рекурсивно обходит папку root_directory, конвертирует .csv в .tsv
    и удаляет исходные .csv файлы.
    """
    csv_count = 0

    # Рекурсивный обход всех папок и подпапок
    for root, dirs, files in os.walk(root_directory):
        for file in files:
            if file.lower().endswith('.csv'):
                csv_path = os.path.join(root, file)
                # Формируем новое имя файла с расширением .tsv
                tsv_path = os.path.splitext(csv_path)[0] + '.tsv'

                print(f"Конвертация: {csv_path} -> {tsv_path}")

                try:
                    # Открываем CSV для чтения и TSV для записи
                    # utf-8-sig корректно обрабатывает файлы из Excel с BOM
                    with open(csv_path, 'r', encoding='utf-8-sig', errors='ignore') as csv_file:
                        # Умное определение разделителя (запятая или точка с запятой)
                        sample = csv_file.read(2048)
                        csv_file.seek(0)

                        if ';' in sample:
                            delimiter = ';'
                        else:
                            delimiter = ','

                        reader = csv.reader(csv_file, delimiter=delimiter)

                        with open(tsv_path, 'w', encoding='utf-8', newline='') as tsv_file:
                            writer = csv.writer(tsv_file, delimiter='\t')

                            for row in reader:
                                writer.writerow(row)

                    # Удаляем старый CSV файл после успешной конвертации
                    os.remove(csv_path)
                    csv_count += 1

                except Exception as e:
                    print(f"❌ Ошибка при обработке файла {csv_path}: {e}")
                    # Если файл записался частично из-за ошибки, удаляем его, чтобы не плодить мусор
                    if os.path.exists(tsv_path):
                        os.remove(tsv_path)

    print(f"\n🎉 Обработка завершена! Успешно конвертировано файлов: {csv_count}")

if __name__ == "__main__":
    # Укажите путь к вашей папке с данными вместо точки '.'
    # Точка означает текущую папку, где запущен скрипт
    target_folder = '.'

    # Подтверждение перед запуском деструктивного действия (удаления)
    absolute_path = os.path.abspath(target_folder)
    confirm = input(f"Вы уверены, что хотите конвертировать ВСЕ CSV в TSV внутри папки:\n{absolute_path}\n(Исходные .csv файлы будут удалены!) [y/n]: ")

    if confirm.lower() == 'y':
        convert_csv_to_tsv(target_folder)
    else:
        print("Отмена операции.")
