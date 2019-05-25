//
//  SpeechRecognition.swift
//  SpeechRecognitionDemo
//
//  Created by Randy Fong on 5/23/19.
//  Copyright © 2019 Randall Fong Inc. All rights reserved.
//

import Foundation
import Speech

enum SpeechToTextErrorType: Error {
    case speechUnauthorized(message: String)
    case unableToContinue(message: String)
    case warning(message: String)
    case informational(message: String)
}

public class SpeechRecognition {
    
    // MARK: - Dependency Injection Properties
    var audioEngine: AVAudioEngine!
    var speechRecognizer: SFSpeechRecognizer?
    var request: SFSpeechAudioBufferRecognitionRequest!
    
    // MARK: - Properties set within class
    var recognitionTask: SFSpeechRecognitionTask?
    var lastSpokenWordRecognized: String!
    
    var isRecording: Bool
    var isAuthorized: Bool
    var authorizedResult = ""
    
    typealias ResultHandler = (Result<String, SpeechToTextErrorType>) -> Void
    
    
    // MARK: - Initialization
    public init() {
        isRecording     = false
        isAuthorized    = false
        lastSpokenWordRecognized = ""
    }
    
    deinit {
        stopAudioSpeechRecognition()
    }
    
    // MARK: -
    func recognizeSpeech(completionHandler: @escaping ResultHandler) {
        requestSpeechAuthorization(completionHandler)
        checkIfSpeechRecognitionAvailable(completionHandler)
        startAudioEngine(completionHandler)
        toggleIsRecording()
        createSpeechRecognitionTask(completionHandler)
    }
        // MARK: - recognizeSpeech - 1. Speech Authorization
        private func requestSpeechAuthorization(_ completionHandler: @escaping ResultHandler) {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                OperationQueue.main.addOperation {
                    switch authStatus {
                    case .authorized:
                        self.isAuthorized = true
                    case .denied:
                        completionHandler(.failure(.speechUnauthorized(message: "User denied access to speech recognition")))
                    case .restricted:
                        completionHandler(.failure(.speechUnauthorized(message: "Speech recognition restricted on this device")))
                    case .notDetermined:
                        completionHandler(.failure(.speechUnauthorized(message: "Speech recognition not yet authorized")))
                    default:
                        completionHandler(.failure(.speechUnauthorized(message: "Undetermined Error")))
                    }
                }
            }
        }
    
        // MARK: - recognizeSpeech - 2. Speech Recognition Check
        private func checkIfSpeechRecognitionAvailable(_ completionHandler: @escaping  ResultHandler) {
            // Check if Speech Recognition is Available
            do {
                try isSpeechRecognitionAvailable()
            } catch SpeechToTextErrorType.unableToContinue(let message) {
                completionHandler(.failure(.unableToContinue(message: message)))
            } catch SpeechToTextErrorType.warning(let message) {
                completionHandler(.failure(.warning(message: message)))
            } catch SpeechToTextErrorType.informational(let message) {
                completionHandler(.failure(.informational(message: message)))
            } catch(let error) {
                fatalError("Speech Recognition Issue: \(error)")
            }
        }
    
            func isSpeechRecognitionAvailable() throws {
                guard let speechRecognizer = speechRecognizer,
                    speechRecognizer.isAvailable
                    else {
                        throw SpeechToTextErrorType.unableToContinue(message: "Speech Recognition Not Available.") }
            }
    
        // MARK: - recognizeSpeech - 3. Start Audio Engine
        private func startAudioEngine(_ completionHandler: @escaping ResultHandler) {
            // Start the Audio Engine
            do {
                try isAudioEngineReadyToStart()
            } catch SpeechToTextErrorType.unableToContinue(let message) {
                completionHandler(.failure(.unableToContinue(message: message)))
            } catch SpeechToTextErrorType.warning(let message) {
                completionHandler(.failure(.warning(message: message)))
            } catch SpeechToTextErrorType.informational(let message) {
                completionHandler(.failure(.informational(message: message)))
            } catch(let error) {
                fatalError("Audio Engine Issue: \(error)")
            }
        }
    
            private func isAudioEngineReadyToStart() throws {
                installTapIntoAudioInput()
                audioEngine.prepare()
                do { try audioEngine.start()
                } catch {
                    fatalError("Audio Engine Issue: \(error)")
                }
            }
    
                private func installTapIntoAudioInput() {
                    let inputNode = audioEngine.inputNode
                    let recordingFormat = inputNode.outputFormat(forBus: 0)
                    inputNode.installTap(onBus: 0,
                                         bufferSize: 512,
                                         format: recordingFormat) { buffer, _ in
                                            self.request.append(buffer)}
                }
    
        // MARK: - recognizeSpeech - 4. Toggle Current Recording Switch
        private func toggleIsRecording() {
            if isRecording {
                isRecording = false
                stopAudioSpeechRecognition()
            } else {
                isRecording = true
            }
        }

        // MARK: - recognizeSpeech - 5. Create Speech Recognition Task
        private func createSpeechRecognitionTask(_ completionHandler: @escaping ResultHandler) {
            // Configure the Speech Recognition Task and Start
            startSpeechRecognitionTask() { result in
                switch result {
                case .success(let phrase):
                    completionHandler(.success(phrase))
                case .failure(let error):
                    switch error {
                    case .speechUnauthorized(_):
                        completionHandler(.failure(.speechUnauthorized(message: self.authorizedResult)))
                    case .unableToContinue(let message):
                        completionHandler(.failure(.unableToContinue(message: message)))
                    case .warning(let message):
                        completionHandler(.failure(.warning(message: message)))
                    case .informational(let message):
                        completionHandler(.failure(.informational(message: message)))
                    }
                }
            }
        }
    
            private func startSpeechRecognitionTask(_ completionHandler: @escaping ResultHandler) {
                lastSpokenWordRecognized = ""
                recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { [unowned self] result, error in
                    if let result = result {
                        let bestString = result.bestTranscription.formattedString
                        self.lastSpokenWordRecognized = bestString
                        completionHandler(.success(bestString))
                    } else if let error = error {
                        if !error.localizedDescription.contains("kAFAssistantErrorDomain error 209.")
                        {
                            print(error)
                            print("Problem recognizing speech. Please try again.")
                        }
                    }
                    
                    self.isRecording = false
                    self.stopAudioSpeechRecognition()
                })
            }

    // MARK: - Audio Controls
    private func stopAudioSpeechRecognition() {
        audioEngine.stop()
        request.endAudio()
        recognitionTask?.finish()
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
