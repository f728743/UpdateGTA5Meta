//
//  ContentViewModel.swift
//  UpdateGTA5Meta
//
//  Created by Alexey Vorobyov on 15.04.2025.
//

//0x0001C468,dlc_mp_low_f_jbib_7_0

//    file: "SOMETHING_GOT_ME_STARTED_REMIX",
//    root: "RADIO_02_POP/something_got_me_started_remix/",
//        Intro(
//            file: "0x12C8ED94",
//            delay: 8.0
//        ),
//        Intro(
//            file: "0x00934929",
//            delay: 8.0
//        )

//something_got_me_started_remix_01
//something_got_me_started_remix_02

import Foundation

@Observable @MainActor
class ContentViewModel {

    func doTheHarlrmShake() {
        
        
        // --- Пример использования ---

        let modelName = "radio_02_pop_something_got_me_started_remix_01" // Пример названия модели из GTA V
//        let modelName = "radio_02_pop_something_got_me_started_remix" // Пример названия модели из GTA V
//        something_got_me_started_remix_01
        let modelHash = joaat(modelName)

        print("Строка: \(modelName)")
        print("Хэш JOAAT (Hex): 0x\(String(format:"%08X", modelHash))")
        
        
        guard let origin = URL(string: "https://raw.githubusercontent.com/tmp-acc/" +
                               "GTA-V-Radio-Stations/master/sim_radio_stations.json")
        else { return }
        
        Task {
            let myRadio = try? await loadSimRadioSeries(url: origin)
        
            guard let myRadio else { return }
            
            let gtrvRadio = RadioStations
            
            let exportedRadio = SimRadioDTO.Series(
                gtrvRadio: RadioStations,
                gtrvNews: RadioNews,
                gtrvAdverts: RadioAdverts
            )
            
            let enriched = exportedRadio.enriched(by: myRadio)
            
//            print(gtrvRadio.map { "\($0.name): \"\($0.root?.lowercased() ?? "--")\""}.joined(separator: "\n"))
            
            saveJSON(gtrvRadio: gtrvRadio, name: "gtrv.json")
            saveJSON(radio: exportedRadio, name: "exported_sim_radio.json")
            saveJSON(radio: enriched, name: "enriched_sim_radio.json")
            saveJSON(radio: myRadio, name: "my_radio.json")
        }
    }
    
    
    func saveJSON(gtrvRadio: [RadioStation], name: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        do {
            let jsonData = try encoder.encode(gtrvRadio)
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError()
            }
            let fileURL = documentsDirectory.appendingPathComponent(name)
            try jsonData.write(to: fileURL, options: .atomic)
            print("JSON successfully saved to file: \(fileURL.path)")

        } catch {
            print("Error encoding or writing JSON: \(error)")
        }
    }
    
    func saveJSON(radio: SimRadioDTO.Series, name: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        do {
            let jsonData = try encoder.encode(radio)
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError()
            }
            let fileURL = documentsDirectory.appendingPathComponent(name)
            try jsonData.write(to: fileURL, options: .atomic)
            print("JSON successfully saved to file: \(fileURL.path)")

        } catch {
            print("Error encoding or writing JSON: \(error)")
        }
    }
    

    func loadSimRadioSeries(url: URL) async throws -> SimRadioDTO.Series {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(SimRadioDTO.Series.self, from: data)
    }
}


extension SimRadioDTO.Series {
    /// Инициализатор для преобразования данных из формата GTRV в SimRadioDTO.
    /// - Parameters:
    ///   - gtrvRadio: Массив радиостанций в формате GTRV.
    ///   - gtrvNews: Массив путей к файлам новостей (без префикса папки и расширения).
    ///   - gtrvAdverts: Массив путей к файлам рекламы (без префикса папки и расширения).
    init(
        gtrvRadio: [RadioStation],
        gtrvNews: [String],
        gtrvAdverts: [String]
    ) {
        // 1. Создаем информацию о серии (пока используем жестко заданные значения)
        let seriesInfo = SimRadioDTO.SeriesInfo(
            title: "GTA V Radio", // Пример названия
            logo: "gta_v.png"     // Пример логотипа (из sim_radio_stations.json)
        )

        // 2. Создаем общие группы файлов (Новости и Реклама)
        //    Предполагается, что пути в gtrvNews/gtrvAdverts - это базовые имена файлов без пути и расширения.
        //    Например, "mono_news_01" из "mono_news_01/MONO_NEWS_01"
        let newsFiles: [SimRadioDTO.File] = gtrvNews.map { newsPathFragment in
            let basePath = newsPathFragment.components(separatedBy: "/").first ?? newsPathFragment
            return SimRadioDTO.File(
                tag: nil,
                path: "common/news/\(basePath).m4a", // Восстанавливаем путь, предполагая структуру
                duration: 0, // TODO: Загрузить реальную длительность (из sim_radio_stations.json или другого источника)
                audibleDuration: nil, // TODO: Загрузить реальную слышимую длительность
                attaches: nil,
                markers: nil
            )
        }
            .sorted { $0.path < $1.path }

        let advertFiles: [SimRadioDTO.File] = gtrvAdverts.map { advertPathFragment in
            let basePath = advertPathFragment.components(separatedBy: "/").first ?? advertPathFragment
            return SimRadioDTO.File(
                tag: nil,
                path: "common/adverts/\(basePath).m4a", // Восстанавливаем путь, предполагая структуру
                duration: 0, // TODO: Загрузить реальную длительность
                audibleDuration: nil, // TODO: Загрузить реальную слышимую длительность
                attaches: nil,
                markers: nil
            )
        }
            .sorted { $0.path < $1.path }

        let commonFileGroups = [
            SimRadioDTO.FileGroup(tag: "adverts", files: advertFiles),
            SimRadioDTO.FileGroup(tag: "news", files: newsFiles)
        ]
        let seriesCommon = SimRadioDTO.SeriesCommon(fileGroups: commonFileGroups)

        // 3. Создаем Станции
        var simStations: [SimRadioDTO.Station] = []

        for gtrvStation in gtrvRadio {
            // Пропускаем станцию "Radio Off" или станции без песен/корневой папки
            guard let stationRoot = gtrvStation.root?.lowercased(),
                  let gtrvSongs = gtrvStation.songs,
                  !gtrvSongs.isEmpty else {
                continue
            }

            // Информация о станции
            let stationInfo = SimRadioDTO.StationInfo(
                title: gtrvStation.name,
                genre: "Unknown", // TODO: Добавить жанр, если он доступен
                logo: "\(stationRoot).png",
                dj: nil // TODO: Добавить DJ, если он доступен
            )

            // Группы файлов станции (Музыка)
            var musicFiles: [SimRadioDTO.File] = []

            for (index, song) in gtrvSongs.enumerated() {
                // --- Создаем Музыкальный Файл ---
                let markers = song.labels.map { label in
                    SimRadioDTO.TrackMarker(
                        title: label.title,
                        artist: label.artist.capitalized,
                        startTime: label.time
                    )
                }

                // Обрабатываем интро (attaches)
                let attachedFiles: [SimRadioDTO.File]? = song.intros.isEmpty ? nil : song.intros.map { intro in
                    // Путь к интро строится относительно корня песни
                    let introPath = "intro/\(intro.file.lowercased()).m4a" // Предполагаем расширение .m4a
                    return SimRadioDTO.File(
                        tag: nil,
                        path: introPath,
                        duration: 0, // TODO: Проверить/исправить логику длительности интро.
                        audibleDuration: nil, // TODO: Загрузить реальную слышимую длительность
                        attaches: nil, // У интро нет дальнейших вложений
                        markers: nil // У интро нет маркеров треков
                    )
                }
                let attaches = attachedFiles.map { SimRadioDTO.Attaches(files: $0) }

                // Полный путь к файлу песни
                let songPath = "\(song.file.lowercased()).m4a" // Предполагаем структуру и расширение .m4a

                let musicFile = SimRadioDTO.File(
                    tag: nil, //song.file, // Используем имя файла песни как тег
                    path: songPath,
                    duration: 0, // TODO: Загрузить реальную длительность песни
                    audibleDuration: nil, // TODO: Загрузить реальную слышимую длительность
                    attaches: attaches, // Добавляем интро как вложения
                    markers: markers
                )
                musicFiles.append(musicFile)

                // Определяем следующий фрагмент (для простой последовательности)
                var nextFragmentRefs: [SimRadioDTO.FragmentRef] = []
                if index < gtrvSongs.count - 1 {
                    // Следующая песня в списке
                    let nextSong = gtrvSongs[index + 1]
                    let nextFragmentTag = "fragment_\(stationRoot)_\(nextSong.file)"
                    nextFragmentRefs.append(SimRadioDTO.FragmentRef(fragmentTag: nextFragmentTag, probability: 1.0))
                } else if let firstSong = gtrvSongs.first {
                     // Последняя песня, зацикливаем на первую
                     let firstFragmentTag = "fragment_\(stationRoot)_\(firstSong.file)"
                     nextFragmentRefs.append(SimRadioDTO.FragmentRef(fragmentTag: firstFragmentTag, probability: 1.0))
                }
            }
            
            let general: SimRadioDTO.FileGroup? = gtrvStation.general.map {
                .init(
                    tag: "general",
                    files: $0.map {
                        SimRadioDTO.File(
                            tag: nil,
                            path: "general/general_\($0.lowercased()).m4a",
                            duration: 0,
                            audibleDuration: nil,
                            attaches: nil,
                            markers: nil
                        )
                    }
                )
            }

            let stationID: SimRadioDTO.FileGroup? = gtrvStation.sid.map {
                .init(
                    tag: "id",
                    files: $0.map {
                        SimRadioDTO.File(
                            tag: nil,
                            path: "id/id_\($0.lowercased()).m4a",
                            duration: 0,
                            audibleDuration: nil,
                            attaches: nil,
                            markers: nil
                        )
                    }
                )
            }

            let monoSolo: SimRadioDTO.FileGroup? = gtrvStation.mono_solo.map {
                .init(
                    tag: "mono_solo",
                    files: $0.map {
                        let path = $0.count < 3 ? "mono_solo/mono_solo_\($0.lowercased()).m4a" : "mono_solo/\($0.lowercased()).m4a"
                        return SimRadioDTO.File(
                            tag: nil,
                            path: path,
                            duration: 0,
                            audibleDuration: nil,
                            attaches: nil,
                            markers: nil
                        )
                    }
                )
            }
            
            let eveningData = gtrvStation.time?["EVENING"] ?? nil
            let morningData = gtrvStation.time?["MORNING"] ?? nil

            
            let evening: SimRadioDTO.FileGroup? = eveningData.map {
                .init(
                    tag: "time_evening",
                    files: $0.map {
                        SimRadioDTO.File(
                            tag: nil,
                            path: "time_evening/evening_\($0.lowercased()).m4a",
                            duration: 0,
                            audibleDuration: nil,
                            attaches: nil,
                            markers: nil
                        )
                    }
                )
            }

            let morning: SimRadioDTO.FileGroup? = morningData.map {
                .init(
                    tag: "time_morning",
                    files: $0.map {
                        SimRadioDTO.File(
                            tag: nil,
                            path: "time_morning/morning_\($0.lowercased()).m4a",
                            duration: 0,
                            audibleDuration: nil,
                            attaches: nil,
                            markers: nil
                        )
                    }
                )
            }
            
            let toNewsData = gtrvStation.to?["NEWS"] ?? nil
            let toAdData = gtrvStation.to?["AD"] ?? nil

            let toNews: SimRadioDTO.FileGroup? = toNewsData.map {
                .init(
                    tag: "to_news",
                    files: $0.map {
                        SimRadioDTO.File(
                            tag: nil,
                            path: "to_news/to_news_\($0.lowercased()).m4a",
                            duration: 0,
                            audibleDuration: nil,
                            attaches: nil,
                            markers: nil
                        )
                    }
                )
            }

            let toAd: SimRadioDTO.FileGroup? = toAdData.map {
                .init(
                    tag: "to_adverts",
                    files: $0.map {
                        SimRadioDTO.File(
                            tag: nil,
                            path: "to_ad/to_ad_\($0.lowercased()).m4a",
                            duration: 0,
                            audibleDuration: nil,
                            attaches: nil,
                            markers: nil
                        )
                    }
                )
            }
            
            // Собираем группы файлов для станции
            let stationFileGroups: [SimRadioDTO.FileGroup] = [
                SimRadioDTO.FileGroup(tag: "track", files: musicFiles),
                general,
                stationID,
                monoSolo,
                evening,
                morning,
                toAd,
                toNews                
            ].compactMap { $0 }


            // Создаем станцию SimRadioDTO
            let simStation = SimRadioDTO.Station(
                tag: stationRoot, // Используем корневой путь как тег станции
                info: stationInfo,
                fileGroups: stationFileGroups,
                playlist: .init(firstFragment: .init(fragmentTag: "---", probability: nil), fragments: [])
            )
            simStations.append(simStation)
        }

        // Финальная сборка SimRadioDTO.Series
        self.init(
            info: seriesInfo,
            common: seriesCommon,
            stations: simStations
        )
    }
}


extension SimRadioDTO.Series {

    /// Создает новую `SimRadioDTO.Series`, обогащенную данными из другой серии.
    /// Заполняет поля `tag`, `duration` и `audibleDuration` для `SimRadioDTO.File`,
    /// если они `nil` или равны 0 в исходной серии (`self`), используя данные из `sourceData`.
    /// Сопоставление файлов происходит по полю `path` в рамках `FileGroup` с одинаковым `tag`
    /// как в `common`, так и в каждой `station`.
    /// Структура `self` остается неизменной.
    ///
    /// - Parameter sourceData: Серия `SimRadioDTO.Series`, содержащая данные для обогащения.
    /// - Returns: Новый экземпляр `SimRadioDTO.Series` с обогащенными данными.
    func enriched(by sourceData: SimRadioDTO.Series) -> SimRadioDTO.Series {

        // --- Словари для быстрого доступа к данным источника ---
        let sourceCommonGroupsLookup = Dictionary(uniqueKeysWithValues: sourceData.common.fileGroups.map { ($0.tag, $0) })
        let sourceStationsLookup = Dictionary(uniqueKeysWithValues: sourceData.stations.map { ($0.tag, $0) })

        // --- 1. Обогащение общих групп файлов (common.fileGroups) ---
        let enrichedCommonFileGroups: [SimRadioDTO.FileGroup] = self.common.fileGroups.map { targetGroup in
            guard let sourceGroup = sourceCommonGroupsLookup[targetGroup.tag] else {
                return targetGroup // Возвращаем оригинальную группу, если нет в источнике
            }

            let sourceFilesLookup = Dictionary(uniqueKeysWithValues: sourceGroup.files.map { ($0.path, $0) })

            let enrichedFiles: [SimRadioDTO.File] = targetGroup.files.map { targetFile in
                if let sourceFile = sourceFilesLookup[targetFile.path] {
                    // Создаем новый файл с обогащенными данными
                    return enrich(file: targetFile, with: sourceFile)
                } else {
                    return targetFile // Возвращаем оригинальный файл, если нет в источнике
                }
            }
            // Создаем новую группу с обогащенными файлами
            return SimRadioDTO.FileGroup(tag: targetGroup.tag, files: enrichedFiles)
        }

        let enrichedCommon = SimRadioDTO.SeriesCommon(fileGroups: enrichedCommonFileGroups)

        // --- 2. Обогащение групп файлов станций (stations) ---
        let enrichedStations: [SimRadioDTO.Station] = self.stations.map { targetStation in
            guard let sourceStation = sourceStationsLookup[targetStation.tag] else {
                return targetStation // Возвращаем оригинальную станцию, если нет в источнике
            }

            let sourceStationGroupsLookup = Dictionary(uniqueKeysWithValues: sourceStation.fileGroups.map { ($0.tag, $0) })

            let enrichedStationFileGroups: [SimRadioDTO.FileGroup] = targetStation.fileGroups.map { targetGroup in
                guard let sourceGroup = sourceStationGroupsLookup[targetGroup.tag] else {
                    return targetGroup // Возвращаем оригинальную группу, если нет в источнике
                }

                let sourceFilesLookup = Dictionary(uniqueKeysWithValues: sourceGroup.files.map { ($0.path, $0) })

                let enrichedFiles: [SimRadioDTO.File] = targetGroup.files.map { targetFile in
                    if let sourceFile = sourceFilesLookup[targetFile.path] {
                         // Создаем новый файл с обогащенными данными
                        return enrich(file: targetFile, with: sourceFile)
                    } else {
                        return targetFile // Возвращаем оригинальный файл, если нет в источнике
                    }
                }
                 // Создаем новую группу с обогащенными файлами
                return SimRadioDTO.FileGroup(tag: targetGroup.tag, files: enrichedFiles)
            }

            // Создаем новую станцию с обогащенными группами файлов
            return SimRadioDTO.Station(
                tag: targetStation.tag,
                info: sourceStation.info, // info обычно не меняется
                fileGroups: enrichedStationFileGroups,
                playlist: sourceStation.playlist // playlist обычно не меняется
            )
        }

        // --- 3. Сборка новой Series ---
        return SimRadioDTO.Series(
            info: sourceData.info,
            common: enrichedCommon,
            stations: enrichedStations
        )
    }

    /// Вспомогательная функция для создания нового `SimRadioDTO.File`
    /// с потенциально обогащенными полями из `sourceFile`.
    ///
    /// - Parameters:
    ///   - targetFile: Оригинальный файл из серии `self`.
    ///   - sourceFile: Файл из `sourceData` для получения данных.
    /// - Returns: Новый экземпляр `SimRadioDTO.File`.
    private func enrich(file targetFile: SimRadioDTO.File, with sourceFile: SimRadioDTO.File) -> SimRadioDTO.File {

        // Определяем значения для нового файла
        let newTag = (targetFile.tag == nil || targetFile.tag?.isEmpty == true)
                     && !(sourceFile.tag?.isEmpty ?? true)
                     ? sourceFile.tag : targetFile.tag

        let newDuration = (targetFile.duration == 0 && sourceFile.duration != 0)
                          ? sourceFile.duration : targetFile.duration

        let newAudibleDuration = (targetFile.audibleDuration == nil || targetFile.audibleDuration == 0)
                                 && (sourceFile.audibleDuration != nil && sourceFile.audibleDuration != 0)
                                 ? sourceFile.audibleDuration : targetFile.audibleDuration

        // Рекурсивно обогащаем вложенные файлы (attaches)
        let newAttaches: SimRadioDTO.Attaches?
        if let targetAttaches = targetFile.attaches, let sourceAttaches = sourceFile.attaches {
            let sourceAttachedFilesLookup = Dictionary(uniqueKeysWithValues: sourceAttaches.files.map { ($0.path, $0) })
            let enrichedAttachedFiles: [SimRadioDTO.File] = targetAttaches.files.map { targetAttachFile in
                if let sourceAttachFile = sourceAttachedFilesLookup[targetAttachFile.path] {
                    return enrich(file: targetAttachFile, with: sourceAttachFile) // Рекурсивный вызов
                } else {
                    return targetAttachFile
                }
            }
            newAttaches = SimRadioDTO.Attaches(files: enrichedAttachedFiles)
        } else {
            newAttaches = targetFile.attaches // Сохраняем оригинальные attaches, если их нет в источнике или target
        }


        // Создаем и возвращаем новый файл
        return SimRadioDTO.File(
            tag: newTag,
            path: targetFile.path, // path - ключ, он не меняется
            duration: newDuration,
            audibleDuration: newAudibleDuration,
            attaches: newAttaches, // Используем обогащенные attaches
            markers: targetFile.markers // markers обычно не меняются
        )
    }
}


/// Вычисляет хэш Jenkins one-at-a-time (JOAAT) для данной строки.
/// GTA V использует этот алгоритм для многих внутренних идентификаторов,
/// обычно хэшируя строки в нижнем регистре.
///
/// - Parameter key: Строка для хэширования.
/// - Returns: 32-битное беззнаковое целое число, представляющее хэш JOAAT.
func joaat(_ key: String) -> UInt32 {
    // Убедимся, что строка в нижнем регистре, как это обычно делается в GTA V
    let lowercasedKey = key.lowercased()
    let bytes = lowercasedKey.utf8

    var hash: UInt32 = 0

    for byte in bytes {
        hash &+= UInt32(byte) // Используем `&+=` для сложения с переносом (wrapping addition)
        hash &+= (hash << 10)
        hash ^= (hash >> 6)
    }

    hash &+= (hash << 3)
    hash ^= (hash >> 11)
    hash &+= (hash << 15)

    return hash
}

