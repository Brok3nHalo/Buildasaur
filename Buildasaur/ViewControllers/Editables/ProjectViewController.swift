//
//  ProjectViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 07/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit
import BuildaUtils
import XcodeServerSDK
import BuildaKit
import BuildaGitServer

protocol ProjectViewControllerDelegate: class {
    func didCancelEditingOfProjectConfig(_ config: ProjectConfig)
    func didSaveProjectConfig(_ config: ProjectConfig)
}

class ProjectViewController: ConfigEditViewController {

    override var availabilityCheckState: AvailabilityCheckState {
        didSet {
            self.trashButton.isHidden = self.availabilityCheckState == .checking
            self.goNextIfPossible()
            self.updateNextAllowed()
        }
    }

    var projectConfig: ProjectConfig! = nil {
        didSet {
            self.project = try? Project(config: self.projectConfig)

            self.authenticator = self.projectConfig.serverAuthentication

            let priv = self.projectConfig.privateSSHKeyPath
            self.privateKeyUrl = priv.isEmpty ? nil : URL(fileURLWithPath: priv)
            let pub = projectConfig.publicSSHKeyPath
            self.publicKeyUrl = pub.isEmpty ? nil : URL(fileURLWithPath: pub)
            self.sshPassphraseTextField.stringValue = projectConfig.sshPassphrase ?? ""
            self.usernameTextFeild.stringValue = projectConfig.username ?? ""
            self.passwordTextField.stringValue = projectConfig.password ?? ""

            self.updateServiceMeta()
        }
    }
    weak var delegate: ProjectViewControllerDelegate?

    var serviceAuthenticator: ServiceAuthenticator!

    private var project: Project! {
        didSet {
            if let workspaceMetadata = self.project?.workspaceMetadata {
                self.projectNameLabel.stringValue = workspaceMetadata.projectName
                self.projectURLLabel.stringValue = workspaceMetadata.projectURL.absoluteString ?? ""
                self.projectPathLabel.stringValue = workspaceMetadata.projectPath
            }
        }
    }

    private var privateKeyUrl: URL? {
        didSet {
            self.selectSSHPrivateKeyButton.title = self.privateKeyUrl?.absoluteString ?? "Select SSH Private Key"
            self.availabilityCheckState = .unchecked
            self.updateNextAllowed()
        }
    }
    private var publicKeyUrl: URL? {
        didSet {
            self.selectSSHPublicKeyButton.title = self.publicKeyUrl?.absoluteString ?? "Select SSH Public Key"
            self.availabilityCheckState = .unchecked
            self.updateNextAllowed()
        }
    }

    private var authenticator: ProjectAuthenticator? {
        didSet {
            let newUserWantsTokenAuth = self.authenticator?.type == .PersonalToken
            if self.userWantsTokenAuth != newUserWantsTokenAuth {
                self.userWantsTokenAuth = newUserWantsTokenAuth
            }
            self.updateServiceMeta()
            self.updateNextAllowed()
        }
    }

    private var userWantsTokenAuth: Bool = false {
        didSet {
            self.updateServiceMeta()
//            self.updateAuthenticator()
        }
    }

    private var username: String = "" {
        didSet {
            self.updateAuthenticator()
        }
    }

    private var password: String = "" {
        didSet {
            self.updateAuthenticator()
        }
    }

    //we have a project
    @IBOutlet weak var projectNameLabel: NSTextField!
    @IBOutlet weak var projectPathLabel: NSTextField!
    @IBOutlet weak var projectURLLabel: NSTextField!

    @IBOutlet weak var publicSSHKeyStackView: NSStackView!
    @IBOutlet weak var privateSSHKeyStackView: NSStackView!
    @IBOutlet weak var sshKeyPassphraseStackView: NSStackView!
    @IBOutlet weak var selectSSHPrivateKeyButton: NSButton!
    @IBOutlet weak var selectSSHPublicKeyButton: NSButton!
    @IBOutlet weak var sshPassphraseTextField: NSSecureTextField!

    //authentication stuff
    @IBOutlet weak var tokenTextField: NSTextField!
    @IBOutlet weak var tokenStackView: NSStackView!
    @IBOutlet weak var usernameTextFeild: NSTextField!
    @IBOutlet weak var usernameStackView: NSStackView!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var passwordStackView: NSStackView!


    @IBOutlet weak var serviceName: NSTextField!
    @IBOutlet weak var serviceLogo: NSImageView!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var useTokenButton: NSButton!
    @IBOutlet weak var logoutButton: NSButton!

    override var editing: Bool {
        didSet {
            self.selectSSHPrivateKeyButton.isEnabled = self.editing
            self.selectSSHPublicKeyButton.isEnabled = self.editing
            self.sshPassphraseTextField.isEnabled = self.editing
            self.tokenTextField.isEnabled = self.editing
            self.usernameTextFeild.isEnabled = self.editing
            self.passwordTextField.isEnabled = self.editing
            self.trashButton.isHidden = self.editing
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.updateNextAllowed()
    }

    func setupUI() {
        self.tokenTextField.delegate = self
        self.sshPassphraseTextField.delegate = self
        self.usernameTextFeild.delegate = self
        self.passwordTextField.delegate = self
    }

    private func updateServiceMeta() {
        if let project = self.project {
            self.updateServiceMeta(project, auth: self.authenticator, userWantsTokenAuth: self.userWantsTokenAuth)
        }
    }

    private func updateAuthenticator() {
        let service = self.project.workspaceMetadata!.service
        if service.serviceType() == .BitBucketEnterprise {
            if username.isEmpty || password.isEmpty {
                self.authenticator = nil
            } else {
                self.authenticator = ProjectAuthenticator(
                    service: service,
                    username: username,
                    type: .Basic,
                    secret: password)
            }
        } else if self.userWantsTokenAuth {
            if self.tokenTextField.stringValue.isEmpty {
                self.authenticator = nil
            } else {
                self.authenticator = ProjectAuthenticator(service: service, username: "GIT", type: .PersonalToken, secret: self.tokenTextField.stringValue)
            }
        }
    }

    private func updateNextAllowed() {
        let isValid = self.privateKeyUrl != nil && self.publicKeyUrl != nil && self.authenticator != nil
        let checker = self.availabilityCheckState != .checking && self.availabilityCheckState != .succeeded
        self.nextAllowed = isValid && checker && self.editing
    }

    func updateServiceMeta(_ proj: Project, auth: ProjectAuthenticator?, userWantsTokenAuth: Bool) {
        guard let service = proj.workspaceMetadata?.service else { return }
        let alreadyHasAuth = auth != nil

        self.loginButton.isHidden = alreadyHasAuth
        self.logoutButton.isHidden = !alreadyHasAuth || service.serviceType() == .BitBucketEnterprise

        let showTokenField = userWantsTokenAuth && proj.workspaceMetadata?.service.serviceType() == .GitHub && (auth?.type == .PersonalToken || auth == nil)
        self.tokenStackView.isHidden = !showTokenField


        let name = "\(service.prettyName())"
        self.serviceName.stringValue = name
        self.serviceLogo.image = NSImage(named: NSImage.Name(rawValue: service.logoName()))

        switch service.serviceType() {
        case .GitHub:
            if let auth = auth, auth.type == .PersonalToken && !auth.secret.isEmpty {
                self.tokenTextField.stringValue = auth.secret
            } else {
                self.tokenTextField.stringValue = ""
            }

            self.usernameStackView.isHidden = true
            self.passwordStackView.isHidden = true
        case .BitBucket:
            self.useTokenButton.isHidden = true
            self.usernameStackView.isHidden = true
            self.passwordStackView.isHidden = true
        case .BitBucketEnterprise:
//            self.publicSSHKeyStackView.isHidden = true
//            self.privateSSHKeyStackView.isHidden = true
//            self.sshKeyPassphraseStackView.isHidden = true
            self.useTokenButton.isHidden = true
            self.loginButton.isHidden = true
        }
    }

    override func shouldGoNext() -> Bool {
        //pull data from UI, create config, save it and try to validate
        guard let newConfig = self.pullConfigFromUI() else { return false }
        self.projectConfig = newConfig
        self.delegate?.didSaveProjectConfig(newConfig)

        //check availability of these credentials
        self.recheckForAvailability(nil)
        return false
    }

    private func goNextIfPossible() {
        if case .succeeded = self.availabilityCheckState {
            //stop editing
            self.editing = false

            //animated!
            delayClosure(delay: 0.2) {
                self.goNext(animated: true)
            }
        }
    }

    func previous() {
        self.goBack()
    }

    private func goBack() {
        let config = self.projectConfig
        self.delegate?.didCancelEditingOfProjectConfig(config!)
    }

    override func delete() {
        //ask if user really wants to delete
        UIUtils.showAlertAskingForRemoval("Do you really want to remove this Xcode Project configuration? This cannot be undone.", completion: { (remove) -> Void in
            if remove {
                self.removeCurrentConfig()
            }
        })
    }

    override func checkAvailability(_ statusChanged: @escaping ((_ status: AvailabilityCheckState) -> Void)) {
        AvailabilityChecker.projectAvailability(config: self.projectConfig, onUpdate: statusChanged)
    }

    func pullConfigFromUI() -> ProjectConfig? {
        let sshPassphrase = self.sshPassphraseTextField.stringValue.nonEmpty()
        guard
            let privateKeyPath = self.privateKeyUrl?.path,
            let publicKeyPath = self.publicKeyUrl?.path,
            let auth = self.authenticator else {
            return nil
        }

        var config = self.projectConfig!
        config.serverAuthentication = auth
        config.sshPassphrase = sshPassphrase
        config.privateSSHKeyPath = privateKeyPath
        config.publicSSHKeyPath = publicKeyPath

        do {
            try self.storageManager.addProjectConfig(config: config)
            return config
        } catch StorageManagerError.DuplicateProjectConfig(let duplicate) {
            let userError = XcodeServerError.with("You already have a Project at \"\(duplicate.url)\", please go back and select it from the previous screen.")
            UIUtils.showAlertWithError(userError)
        } catch {
            UIUtils.showAlertWithError(error)
        }
        return nil
    }

    func removeCurrentConfig() {
        let config = self.projectConfig!
        self.storageManager.removeProjectConfig(projectConfig: config)
        self.goBack()
    }

    func selectKey(_ type: String) {
        if let url = StorageUtils.openSSHKey(publicOrPrivate: type) {
            do {
                _ = try String(contentsOf: url, encoding: String.Encoding.ascii)
                if type == "public" {
                    self.publicKeyUrl = url
                } else {
                    self.privateKeyUrl = url
                }
            } catch {
                UIUtils.showAlertWithError(error as NSError)
            }
        }
    }

    @IBAction func selectPublicKeyTapped(_ sender: AnyObject) {
        self.selectKey("public")
    }

    @IBAction func selectPrivateKeyTapped(_ sender: AnyObject) {
        self.selectKey("private")
    }

    @IBAction func loginButtonClicked(_ sender: AnyObject) {

        self.userWantsTokenAuth = false

        guard let service = self.project.workspaceMetadata?.service else {
            UIUtils.showAlertWithError(XcodeServerError.with("Workspace invalid"))
            return
        }

        if service.serviceType() == .BitBucketEnterprise {

        } else {
            self.serviceAuthenticator.getAccess(service) { (auth, _) -> Void in

                guard let auth = auth else {
                    //TODO: show UI error that login failed
                    UIUtils.showAlertWithError(XcodeServerError.with("Failed to log in, please try again"))
                    self.authenticator = nil
                    return
                }

                //we have been authenticated, hooray!
                self.authenticator = auth
            }
        }
    }

    @IBAction func useTokenClicked(_ sender: AnyObject) {
        self.userWantsTokenAuth = true
    }

    @IBAction func logoutButtonClicked(_ sender: AnyObject) {
        self.authenticator = nil
        self.userWantsTokenAuth = false
        self.tokenTextField.stringValue = ""
        self.updateServiceMeta()
    }

}

extension ProjectViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if textField == self.tokenTextField
                || textField == self.sshPassphraseTextField {
                self.availabilityCheckState = .unchecked
                self.updateNextAllowed()
            } else if textField == self.tokenTextField {
                self.updateAuthenticator()
            } else if textField == self.usernameTextFeild {
                self.username = textField.stringValue
            } else if textField == self.passwordTextField {
                self.password = textField.stringValue
            }
        }
    }
}
