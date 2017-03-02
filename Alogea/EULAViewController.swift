//
//  EULAViewController.swift
//  Alogea
//
//  Created by mikeMBP on 12/02/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit

class EULAViewController: UIViewController {

    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var confirmationLabel: UILabel!
    
    var rootViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //textView.isHidden = true
        textView.text = touHeader + purposeAlimitations + dataSecurity + privacy + eulaText + generalEULA1 + generalEULA2 + generalEULA3 + generalEULA4 + generalEULA5 + generalEULA6 + generalEULA7 + generalEULA8 + generalEULA9 + generalEULA10 + generalEULA11 + generalEULA12 + generalEULA13

        updateConfirmationLabel()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        textView.scrollRangeToVisible(NSMakeRange(0,0))
//        textView.isHidden = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateConfirmationLabel() {
        
        if UserDefaults.standard.value(forKey: "TOUAccepted") != nil {
            
            if UserDefaults.standard.bool(forKey: "TOUAccepted") == true {
                confirmationLabel.textColor = UIColor.blue
                confirmationLabel.text = "You accepted these Terms of Use on \(UserDefaults.standard.value(forKey: "TOUAcceptanceDate")!)"
            } else {
                confirmationLabel.textColor = UIColor.red
                confirmationLabel.text = "You declined these Terms of Use on \(UserDefaults.standard.value(forKey: "TOUAcceptanceDate")!)\nThe App cannot be used without accepting the terms\nPlease either accept the terms below or press the home button to exit."
            }
            
        } else {
            confirmationLabel.text = "You must accept the Terms Of Use in order to use this App"
            confirmationLabel.sizeToFit()
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func declineAction(_ sender: UIButton) {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter
        }()

        UserDefaults.standard.set(false, forKey: "TOUAccepted")
        UserDefaults.standard.set(dateFormatter.string(from: Date()), forKey: "TOUAcceptanceDate")
        updateConfirmationLabel()
    }

    @IBAction func acceptAction(_ sender: Any) {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateStyle = .short
            return formatter
        }()
        
        UserDefaults.standard.set(true, forKey: "TOUAccepted")
        UserDefaults.standard.set(dateFormatter.string(from: Date()), forKey: "TOUAcceptanceDate")
        updateConfirmationLabel()
        self.dismiss(animated: true, completion: {
            self.removeFromParentViewController()
        })
    }
    
    func showTOUMessage() {
        
        // this presents the same on iPads and iPhones
        let termsOfUseDialog = UIAlertController(title: "Important", message: "To protect you data your device must be protected with a pass code. You must obtain professional clinical advice about using medicines; this App is not a substitute for medical advice.", preferredStyle: .alert)
        
        let acknowledgeAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: { (UIAlertController)
            -> Void in
        })
        
        
        termsOfUseDialog.addAction(acknowledgeAction)
        
        self.present(termsOfUseDialog, animated: true, completion: nil)
    }
    
    let purposeAlimitations = "I. PURPOSE AND LIMITATIONS OF APP USE\nAlogea® is intended as a personal support tool to assist you in monitoring and managing your day-to-day pain and pain-related problems.\nYou understand that Alogea® it NOT intended to guide or give advice on medical treatment or diagnosis. You must obtain qualified medical advice before taking, or refraining from taking, medicines or actions on the basis of the content of this App.\n\nYou understand that use of the App must not replace or delay professional clinical advice; you must follow this advice and the instructions of your treating clinician.\nYOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT YOU MUST CONSULT YOUR RESPONSIBLE CLINICIAN / PRESCRIBER BEFORE MAKING CHANGES TO YOUR MEDICATION. YOU MUST NOT DEVIATE FROM THE RECOMMENDED WAY OF TAKING MEDICINES AS A CONSEQUENCE OF USING THIS APP WITHOUT PRIOR DISCUSSION WITH YOUR RESPONSIBLE CLINICIAN/ PRESCRIBER.\n\n"
    let dataSecurity = "II. DATA SECURITY\nFor your data to be encrypted by standard iOS® encryption tools and stored safely you must protect all devices Alogea® is installed on with suitable passcode protection. IF YOU DO NOT USE DEVICE PASSCODE PROTECTION YOUR DATA IS NOT ENCRYPTED AND CAN BE READ BY OTHERS.\n\nTo reduce the risk of data loss, and the consequences of data corruption, it is STRONGLY RECOMMENDED TO MAKE BACKUPS regularly in the ‘Settings’ section. Loss of, or corruption of data, is subject to liability limitations in section e. of the GENERAL END USER LICENSE AGREEMENT.\n\n"
    let privacy = "III. PRIVACY\n\nWe may collect and process data about you. This includes information you give us when downloading Alogea® or Alogea® expansions, as well as technical information about your device and related software, hardware and peripherals. It also includes details of your use of Alogea® and related services unless you have opted out in your Apple account settings. We will not store or share your personal data as far as is not required by law / regulations. AppToolFactory and Apple may use the above information, as long as it is in a form that does not personally identify You, to improve its products or to provide services or technologies to you.\n\n"
    
    //To continue to improve Alogea® and related services we may process data contained in error messages to idenfity code errors. These will not be shared, will be stored in anonymised form only and deleted once their purpose has been achieved."
    let generalEULA1 = "Alogea® is licensed, not sold, to You for use only under the Terms of Use. The licensor ('Application Provider') reserves all rights not expressly granted to You. The Alogea® App and related services are referred to in this license as the 'Licensed Application'.\n\n"
    let generalEULA2 = "a. Scope of License: This license granted to You for the Licensed Application by Application Provider is limited to a non-transferable license to use the Licensed Application on any iPhone or iPod touch that You own or control and as permitted by the Usage Rules set forth in Section 9.b. of the App Store Terms and Conditions (the “Usage Rules”). This license does not allow You to use the Licensed Application on any iPod touch or iPhone that You do not own or control, and You may not distribute or make the Licensed Application available over a network where it could be used by multiple devices at the same time. You may not rent, lease, lend, sell, redistribute or sublicense the Licensed Application. You may not copy (except as expressly permitted by this license and the Usage Rules), decompile, reverse engineer, disassemble, attempt to derive the source code of, modify, or create derivative works of the Licensed Application, any updates, or any part thereof (except as and only to the extent any foregoing restriction is prohibited by applicable law or to the extent as may be permitted by the licensing terms governing use of any open sourced components included with the Licensed Application). Any attempt to do so is a violation of the rights of the Application Provider and its licensors. If You breach this restriction, You may be subject to prosecution and damages. The terms of the license will govern any upgrades provided by Application Provider that replace and/or supplement the original Product, unless such upgrade is accompanied by a separate license in which case the terms of that license will govern.\n\n"
    
//    let generalEULA3 = "b. Consent to Use of Data: You agree that Application Provider may collect and use technical data and related information, including but not limited to technical information about Your device, system and application software, and peripherals, that is gathered periodically to facilitate the provision of software updates, product support and other services to You (if any) related to the Licensed Application. Application Provider may use this information, as long as it is in a form that does not personally identify You, to improve its products or to provide services or technologies to You."
    
    let generalEULA3 = "b. Termination. The license is effective until terminated by You or Application Provider. Your rights under this license will terminate automatically without notice from the Application Provider if You fail to comply with any term(s) of this license. Upon termination of the license, You shall cease all use of the Licensed Application, and destroy all copies, full or partial, of the Licensed Application.\n\n"
    
    let generalEULA4 = "c. Services; Third Party Materials. The Licensed Application may enable access to Application Provider’s and third party services and web sites (collectively and individually, 'Services'). Use of the Services may require Internet access and that You accept additional terms of service.\n\n"
    
    let generalEULA5 = "You understand that by using any of the Services, You may encounter content that may be deemed offensive, indecent, or objectionable, which content may or may not be identified as having explicit language, and that the results of any search or entering of a particular URL may automatically and unintentionally generate links or references to objectionable material. Nevertheless, You agree to use the Services at Your sole risk and that the Application Provider shall not have any liability to You for content that may be found to be offensive, indecent, or objectionable."
    
    let generalEULA6 = "Certain Services may display, include or make available content, data, information, applications or materials from third parties (“Third Party Materials”) or provide links to certain third party web sites. By using the Services, You acknowledge and agree that the Application Provider is not responsible for examining or evaluating the content, accuracy, completeness, timeliness, validity, copyright compliance, legality, decency, quality or any other aspect of such Third Party Materials or web sites. The Application Provider does not warrant or endorse and does not assume and will not have any liability or responsibility to You or any other person for any third-party Services, Third Party Materials or web sites, or for any other materials, products, or services of third parties. Third Party Materials and links to other web sites are provided solely as a convenience to You. Financial information displayed by any Services is for general informational purposes only and is not intended to be relied upon as investment advice. Before executing any securities transaction based upon information obtained through the Services, You should consult with a financial professional. Location data provided by any Services is for basic navigational purposes only and is not intended to be relied upon in situations where precise location information is needed or where erroneous, inaccurate or incomplete location data may lead to death, personal injury, property or environmental damage. Neither the Application Provider, nor any of its content providers, guarantees the availability, accuracy, completeness, reliability, or timeliness of stock information or location data displayed by any Services.\n"
    
    let generalEULA7 = "You agree that any Services contain proprietary content, information and material that is protected by applicable intellectual property and other laws, including but not limited to copyright, and that You will not use such proprietary content, information or materials in any way whatsoever except for permitted use of the Services. No portion of the Services may be reproduced in any form or by any means. You agree not to modify, rent, lease, loan, sell, distribute, or create derivative works based on the Services, in any manner, and You shall not exploit the Services in any unauthorized way whatsoever, including but not limited to, by trespass or burdening network capacity. You further agree not to use the Services in any manner to harass, abuse, stalk, threaten, defame or otherwise infringe or violate the rights of any other party, and that the Application Provider is not in any way responsible for any such use by You, nor for any harassing, threatening, defamatory, offensive or illegal messages or transmissions that You may receive as a result of using any of the Services.\n"
    
    let generalEULA8 = "In addition, third party Services and Third Party Materials that may be accessed from, displayed on or linked to from the iPhone or iPod touch are not available in all languages or in all countries. The Application Provider makes no representation that such Services and Materials are appropriate or available for use in any particular location. To the extent You choose to access such Services or Materials, You do so at Your own initiative and are responsible for compliance with any applicable laws, including but not limited to applicable local laws. The Application Provider, and its licensors, reserve the right to change, suspend, remove, or disable access to any Services at any time without notice. In no event will the Application Provider be liable for the removal of or disabling of access to any such Services. The Application Provider may also impose limits on the use of or access to certain Services, in any case and without notice or liability.\n\n"
    
    let generalEULA9 = "d. NO WARRANTY: YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT USE OF THE LICENSED APPLICATION IS AT YOUR SOLE RISK AND THAT THE ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY AND EFFORT IS WITH YOU. TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE LICENSED APPLICATION AND ANY SERVICES PERFORMED OR PROVIDED BY THE LICENSED APPLICATION ('SERVICES') ARE PROVIDED 'AS IS' AND 'AS AVAILABLE', WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND, AND APPLICATION PROVIDER HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS WITH RESPECT TO THE LICENSED APPLICATION AND ANY SERVICES, EITHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES AND/OR CONDITIONS OF MERCHANTABILITY, OF SATISFACTORY QUALITY, OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY, OF QUIET ENJOYMENT, AND NON-INFRINGEMENT OF THIRD PARTY RIGHTS. APPLICATION PROVIDER DOES NOT WARRANT AGAINST INTERFERENCE WITH YOUR ENJOYMENT OF THE LICENSED APPLICATION, THAT THE FUNCTIONS CONTAINED IN, OR SERVICES PERFORMED OR PROVIDED BY, THE LICENSED APPLICATION WILL MEET YOUR REQUIREMENTS, THAT THE OPERATION OF THE LICENSED APPLICATION OR SERVICES WILL BE UNINTERRUPTED OR ERROR-FREE, OR THAT DEFECTS IN THE LICENSED APPLICATION OR SERVICES WILL BE CORRECTED. NO ORAL OR WRITTEN INFORMATION OR ADVICE GIVEN BY APPLICATION PROVIDER OR ITS AUTHORIZED REPRESENTATIVE SHALL CREATE A WARRANTY. SHOULD THE LICENSED APPLICATION OR SERVICES PROVE DEFECTIVE, YOU ASSUME THE ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES OR LIMITATIONS ON APPLICABLE STATUTORY RIGHTS OF A CONSUMER, SO THE ABOVE EXCLUSION AND LIMITATIONS MAY NOT APPLY TO YOU.\n\n"
    
    let generalEULA10 = "e. Limitation of Liability. TO THE EXTENT NOT PROHIBITED BY LAW, IN NO EVENT SHALL APPLICATION PROVIDER BE LIABLE FOR PERSONAL INJURY, OR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES WHATSOEVER, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, LOSS OF DATA, BUSINESS INTERRUPTION OR ANY OTHER COMMERCIAL DAMAGES OR LOSSES, ARISING OUT OF OR RELATED TO YOUR USE OR INABILITY TO USE THE LICENSED APPLICATION, HOWEVER CAUSED, REGARDLESS OF THE THEORY OF LIABILITY (CONTRACT, TORT OR OTHERWISE) AND EVEN IF APPLICATION PROVIDER HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. SOME JURISDICTIONS DO NOT ALLOW THE LIMITATION OF LIABILITY FOR PERSONAL INJURY, OR OF INCIDENTAL OR CONSEQUENTIAL DAMAGES, SO THIS LIMITATION MAY NOT APPLY TO YOU. In no event shall Application Provider’s total liability to you for all damages (other than as may be required by applicable law in cases involving personal injury) exceed the amount of fifty dollars ($50.00). The foregoing limitations will apply even if the above stated remedy fails of its essential purpose.\n\n"
    
    let generalEULA11 = "f. You may not use or otherwise export or re-export the Licensed Application except as authorized by United States law and the laws of the jurisdiction in which the Licensed Application was obtained. In particular, but without limitation, the Licensed Application may not be exported or re-exported (a) into any U.S. embargoed countries or (b) to anyone on the U.S. Treasury Department's list of Specially Designated Nationals or the U.S. Department of Commerce Denied Person’s List or Entity List. By using the Licensed Application, you represent and warrant that you are not located in any such country or on any such list. You also agree that you will not use these products for any purposes prohibited by United States law, including, without limitation, the development, design, manufacture or production of nuclear, missiles, or chemical or biological weapons.\n\n"
    
    let generalEULA12 = "g. The Licensed Application and related documentation are 'Commercial Items', as that term is defined at 48 C.F.R. §2.101, consisting of 'Commercial Computer Software' and 'Commercial Computer Software Documentation', as such terms are used in 48 C.F.R. §12.212 or 48 C.F.R. §227.7202, as applicable. Consistent with 48 C.F.R. §12.212 or 48 C.F.R. §227.7202-1 through 227.7202-4, as applicable, the Commercial Computer Software and Commercial Computer Software Documentation are being licensed to U.S. Government end users (a) only as Commercial Items and (b) with only those rights as are granted to all other end users pursuant to the terms and conditions herein. Unpublished-rights reserved under the copyright laws of the United States.\n\n"
    
    let generalEULA13 = "h. The laws of the United Kingdom govern this license and your use of the Licensed Application. Your use of the Licensed Application may also be subject to other local, state, national, or international laws."
    
    let touHeader = "SPECIFIC TERMS OF USE\n\n"
    
    let eulaText = "IV. GENERAL TERMS OF USE\n"

}
