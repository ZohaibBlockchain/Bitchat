import Foundation
import libPhoneNumber_iOS

/// Set of methods to be able to login to an existing account on a homeserver.
///
/// More documentation can be found in the file https://github.com/vector-im/element-android/blob/main/docs/signin.md
class LoginWizard {
    struct State {
        /// For SSO session recovery
        var deviceId: String?
        var resetPasswordEmail: String?
        var resetPasswordData: ResetPasswordData?
        
        var clientSecret = UUID().uuidString
        var sendAttempt: UInt = 0
    }
    
    let client: AuthenticationRestClient
    let sessionCreator: SessionCreatorProtocol
    
    private(set) var state: State
    
    init(client: AuthenticationRestClient, sessionCreator: SessionCreatorProtocol) {
        self.client = client
        self.sessionCreator = sessionCreator
        
        state = State()
    }
    
    /// Login to the homeserver.
    /// - Parameters:
    ///   - login: The login field. Can be a user name, or a msisdn (email or phone number) associated to the account.
    ///   - password: The password of the account.
    ///   - initialDeviceName: The initial device name.
    ///   - deviceID: The device ID, optional. If not provided or nil, the server will generate one.
    ///   - removeOtherAccounts: If set to true, existing accounts with different user identifiers will be removed.
    /// - Returns: An `MXSession` if the login is successful.
    
    
    
    func login(login: String,
               password: String,
               initialDeviceName: String,
               deviceID: String? = nil,
               removeOtherAccounts: Bool = false) async throws -> MXSession {
        let parameters: LoginPasswordParameters
        
        if MXTools.isEmailAddress(login) {
            parameters = LoginPasswordParameters(id: .thirdParty(medium: .email, address: login),
                                                 password: password,
                                                 deviceDisplayName: initialDeviceName,
                                                 deviceID: deviceID)
        } else if let number = try? NBPhoneNumberUtil.sharedInstance().parse(login, defaultRegion: nil),
                  NBPhoneNumberUtil.sharedInstance().isValidNumber(number) {
            let msisdn = login.replacingOccurrences(of: "+", with: "")
            parameters = LoginPasswordParameters(id: .thirdParty(medium: .msisdn, address: msisdn),
                                                 password: password,
                                                 deviceDisplayName: initialDeviceName,
                                                 deviceID: deviceID)
        } else {
            parameters = LoginPasswordParameters(id: .user(login),
                                                 password: password,
                                                 deviceDisplayName: initialDeviceName,
                                                 deviceID: deviceID)
        }
        
        
        
        let credentials = try await client.login(parameters: parameters)
        let session = await sessionCreator.createSession(credentials: credentials, client: client, removeOtherAccounts: removeOtherAccounts)
           print("Login successful for user: \(login)")

           // Set retention policy for all rooms
        setRetentionPolicyForAllRooms(session: session, maxLifetime: 1000 * 60 * 1, minLifetime: 1000 * 60 * 1) { success in
            if success {
                print("Retention policy successfully set for all rooms")
            } else {
                print("Failed to set retention policy for one or more rooms")
            }
        }

           return session
    }

    
    
    
    
    
    /// Exchange a login token to an access token.
    /// - Parameters:
    ///   - token: A login token, obtained when login has happened in a WebView, using SSO.
    ///   - removeOtherAccounts: If set to true, existing accounts with different user identifiers will be removed.
    /// - Returns: An `MXSession` if the login is successful.
    func login(with token: String, removeOtherAccounts: Bool = false) async throws -> MXSession {
        let parameters = LoginTokenParameters(token: token)
        
        
        
        let credentials = try await client.login(parameters: parameters)
     
        let session = await sessionCreator.createSession(credentials: credentials, client: client, removeOtherAccounts: removeOtherAccounts)
           print("Login successful for user: \(credentials)")

           // Set retention policy for all rooms
        setRetentionPolicyForAllRooms(session: session, maxLifetime: 1000 * 60 * 1, minLifetime: 1000 * 60 * 1) { success in
            if success {
                print("Retention policy successfully set for all rooms")
            } else {
                print("Failed to set retention policy for one or more rooms")
            }
        }

           return session
        
        
    }

    /// Ask the homeserver to reset the user password. The password will not be
    /// reset until `resetPasswordMailConfirmed` is successfully called.
    /// - Parameters:
    ///   - email: An email previously associated to the account the user wants the password to be reset.
    func resetPassword(email: String) async throws {
        let result = try await client.forgetPassword(for: email,
                                                     clientSecret: state.clientSecret,
                                                     sendAttempt: state.sendAttempt)

        state.sendAttempt += 1
        state.resetPasswordData = ResetPasswordData(addThreePIDSessionID: result)
    }

    /// Confirm the new password, once the user has checked their email.
    /// When this method succeeds, the account password will be effectively modified.
    /// - Parameters:
    ///   - newPassword: The desired new password
    ///   - signoutAllDevices: The flag to sign out of all devices
    func resetPasswordMailConfirmed(newPassword: String, signoutAllDevices: Bool) async throws {
        guard let resetPasswordData = state.resetPasswordData else {
            MXLog.error("[LoginWizard] resetPasswordMailConfirmed: Reset password data missing. Call resetPassword first.")
            throw LoginError.resetPasswordNotStarted
        }
        
        let parameters = CheckResetPasswordParameters(clientSecret: state.clientSecret,
                                                      sessionID: resetPasswordData.addThreePIDSessionID,
                                                      newPassword: newPassword,
                                                      signoutAllDevices: signoutAllDevices)
        
        try await client.resetPassword(parameters: parameters)
        
        state.resetPasswordData = nil
    }
    
    
    
    private func setRetentionPolicyForRoom(session: MXSession, roomId: String, maxLifetime: Int, minLifetime: Int, completion: @escaping (Result<Any, Error>) -> Void) {
        
        
        
        
        guard let room = session.room(withRoomId: roomId) else {
            print("Room with ID \(roomId) not found")
            completion(.failure(NSError(domain: "MatrixClientError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Room not found"])))
            return
        }

        // Fetch current retention policy from the room state
        room.state { roomState in
            if let currentPolicy = roomState?.stateEvents.first(where: { $0.type == "m.room.retention" })?.content as? [String: Any],
               let currentMaxLifetime = currentPolicy["max_lifetime"] as? Int,
               let currentMinLifetime = currentPolicy["min_lifetime"] as? Int {
                
                // Check if the current policy matches the desired policy
                if currentMaxLifetime == maxLifetime && currentMinLifetime == minLifetime {
                    print("Retention policy already set for room: \(roomId) with max_lifetime: \(currentMaxLifetime) and min_lifetime: \(currentMinLifetime)")
                    completion(.success(currentPolicy))
                    return
                }
            }

            // Set the retention policy if not already set or if different
            let content: [String: Any] = [
                "max_lifetime": maxLifetime,
                "min_lifetime": minLifetime
            ]

            room.sendStateEvent(.custom("m.room.retention"), content: content, stateKey: "") { response in
                switch response {
                case .success(let object):
                    print("Retention policy set successfully for room: \(roomId)")
                    completion(.success(object))
                case .failure(let error):
                    print("Failed to set retention policy for room \(roomId): \(error)")
                    completion(.failure(error))
                }
            }
        }
    }


    
    
    
    private func setRetentionPolicyForAllRooms(session: MXSession, maxLifetime: Int, minLifetime: Int, completion: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        var allOperationsSuccessful = true

        print("---x----")
        print("|||: ", session.rooms.count)
        
        session.rooms.forEach { room in
            if let roomId = room.roomId {
                
                print("---xobi: ", roomId)
                
                dispatchGroup.enter()
                setRetentionPolicyForRoom(session: session, roomId: roomId, maxLifetime: maxLifetime, minLifetime: minLifetime) { result in
                    if case .failure = result {
                        allOperationsSuccessful = false
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(allOperationsSuccessful)
        }
    }

    
    

}
