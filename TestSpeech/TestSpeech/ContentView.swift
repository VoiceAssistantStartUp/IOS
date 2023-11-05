//
//  ContentView.swift
//  TestSpeech
//
//  Created by Kostyantin on 15.10.2023.
//
//
import SwiftUI
import AVFoundation
import Speech

class SpeechRec: ObservableObject {
    @Published private(set) var recognitionState = ""
    @Published private(set) var recognizedText: String = ""
    private var lastRecognizedText: String = ""
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // за допомогою цього я пофіксив звук - при ініціалізації ми
    init() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // по дефолту ми надсилаємо звук в динамік (.defaultToSpeaker)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            // ну і активуємо цю конфігурацію(взагалі хз чого це було початково, можливо цей ініт варто було б зробити першим ділом)
            try audioSession.setActive(true)
        } catch {
            print("Setting up audio session failed: \(error)")
        }
    }
    
    // записуємо всі наші файли в папку assistant
    private var recordingsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("assistant")
    }
    
    // створюємо новий файл, по хардкору єбашим +1 до назви нового поки існує файл з таким ID
    private func nextAudioFileURL() -> URL {
        let fileManager = FileManager.default
        try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true, attributes: nil)
        
        var nextID = 1
        while fileManager.fileExists(atPath: recordingsDirectory.appendingPathComponent("\(nextID).caf").path) {
            nextID += 1
        }
        
        return recordingsDirectory.appendingPathComponent("\(nextID).caf")
    }
    
    var audioPlayer: AVAudioPlayer?
    var audioFile: AVAudioFile?
    
    func playRecordedAudio(from url: URL) {
        if let player = try? AVAudioPlayer(contentsOf: url) {
            self.audioPlayer = player
            player.play()
        }
    }
    
    func deleteAllRecordings() {
        let fileManager = FileManager.default
        let recordings = allRecordings()

        for recording in recordings {
            do {
                try fileManager.removeItem(at: recording)
            } catch {
                print("Failed to delete \(recording): \(error)")
            }
        }
        objectWillChange.send()
    }
    
    func start() {
        self.speak(message: "Recording in progress.")
        self.recognitionState = "Listening..."
        
        //  в старт додав функцію, яка спочатку шукає перший доступний ID і записує туди
        let newURL = nextAudioFileURL()
        do {
            audioFile = try AVAudioFile(forWriting: newURL, settings: audioEngine.inputNode.outputFormat(forBus: 0).settings)
        } catch {
            print("Failed to create audio file for writing:", error)
        }
        // Затримка на 2 секунди при початку, бо в іншому випадку записує системний Listening to you...
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            SFSpeechRecognizer.requestAuthorization { status in
                self.startRecognition()
            }
        }
    }
    
    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioFile = nil
        // btw, якийсь довгий текст при стопі, можливо придумай щось коротше трохи
        self.recognitionState = "Recognition Stopped"
        self.speak(message: "Recording saved.")
    }
    
    func speak(message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
    

    func startRecognition() {
        do {
            if audioEngine.isRunning {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
                audioEngine.reset()
            }
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    let newRecognizedText = result.bestTranscription.formattedString
                    if newRecognizedText != self.lastRecognizedText {
                        self.recognizedText = newRecognizedText
                        self.lastRecognizedText = newRecognizedText
                    }
                }
            }
            print(self.recognizedText, "Print recognition task")
            
            let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
                print(self.recognizedText, "Print engine recording format")
                
                do {
                    try self.audioFile?.write(from: buffer)
                } catch {
                    print("Failed to write buffer to audio file:", error)
                }
                
                print(self.recognizedText, "Print engine recording format")
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            print(self.recognizedText, "Print audio engine start")
        } catch {
            print(error)
        }
    }
    
    // функція, яка повертає нам наші записи в assistant, фільтруючи про .caf(якесь незрозуміле розширення макось
    func allRecordings() -> [URL] {
            let fileManager = FileManager.default
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil)
                return fileURLs.filter { $0.pathExtension == "caf" }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            } catch {
                print("Error while fetching recordings:", error)
                return []
            }
        }
    }

struct BackgroundColorStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    func body(content: Content) -> some View {
        let startColor: Color
        let endColor: Color

        if colorScheme == .light {
            startColor = Color(#colorLiteral(red: 0.1647058824, green: 0.1764705882, blue: 0.1960784314, alpha: 1))
            endColor = Color(#colorLiteral(red: 0.131372549, green: 0.07450980392, blue: 0.07450980392, alpha: 1))
        } else {
            startColor = Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.24))
            endColor = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0))
        }

        return content.background(
            LinearGradient(gradient: Gradient(colors: [startColor, endColor]), startPoint: .top, endPoint: .bottom)
        )
    }
}

struct CustomTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(red: 250/255, green: 250/255, blue: 250/255, opacity: 0.93))
            .font(Font.custom("Anton", size: 40))
            .fontWeight(.bold)
            .lineSpacing(10)
            .padding(.horizontal, 20)
    }
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(10)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color(#colorLiteral(red: 0.1254901961, green: 0.1294117647, blue: 0.1294117647, alpha: 1)))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CustomVStackStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color(#colorLiteral(red: 0.1254901961, green: 0.1294117647, blue: 0.1294117647, alpha: 1)))
            )
    }
}

struct ContentView: View {
    @ObservedObject var speechRec = SpeechRec()
    @State private var isListening = false
    @State private var selectedRecording: URL? = nil
    @State private var showingDeleteAlert = false   // To show alert before deleting

    var body: some View {
        GeometryReader { metrics in
            VStack {
                Text("**MADOK VOICE RECORDER**")
                    .modifier(CustomTextStyle())
                    .padding(.vertical, 30)
                Spacer()
                VStack {
                    if (!isListening) {
                        HStack {
                            Button(action: {
                                self.showingDeleteAlert = true
                            }, label: {
                                Label("Delete all", systemImage: "xmark.circle")
                                    .padding(5)
                            })
                            .foregroundColor(.white)
                            .padding(.top, 10)
                            .actionSheet(isPresented: $showingDeleteAlert) {
                                ActionSheet(title: Text("Delete All Recordings"), message: Text("Are you sure you want to delete all recordings? This action cannot be undone."), buttons: [
                                    .destructive(Text("Delete All")) {
                                        self.speechRec.deleteAllRecordings()
                                    },
                                    .cancel()
                                ])
                            }
                        }
                        List(speechRec.allRecordings(), id: \.self) { url in
                            HStack {
                                Text(url.lastPathComponent)
                                Spacer()
                                Button(action: {
                                    self.playRecording(from: url)
                                }) {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        Text("Last recording result:")
                        List {
                            Text(speechRec.recognizedText)
                                .padding(10)
                                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity, alignment: .leading)
                                .background(.clear)
                        }
                        .scrollContentBackground(.hidden)
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity, alignment: .leading)
                    }
                }
                .modifier(CustomVStackStyle())
                .frame(width: metrics.size.width * 0.90, height: metrics.size.height * 0.5)
                
                Spacer()
                
                Button(action: {
                    if isListening {
                        self.speechRec.stop()
                    } else {
                        self.speechRec.start()
                    }
                    isListening.toggle()
                }) {
                    Text(isListening ? "Stop Listening" : "Start Listening")
                        .modifier(CustomTextStyle())
                }
                    .buttonStyle(CustomButtonStyle())
           }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 40)
            .edgesIgnoringSafeArea(.all)
            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime), perform: { _ in
                self.selectedRecording = nil
            })
            .onAppear {
                self.speechRec.objectWillChange.send()
            }
            .modifier(BackgroundColorStyle())
        }
    }
    
    func playRecording(from url: URL) {
        speechRec.playRecordedAudio(from: url)
    }
}
