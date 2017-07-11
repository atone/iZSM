//
//  DonationViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/11.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SafariServices

class DonationViewController: UIViewController {

    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
        let textFont = UIFont(name: "HYXinRenWenSongW", size: fontDescriptor.pointSize)
        textLabel.font = textFont
        textLabel.text = "感谢您对最水木的支持与喜爱！\n您的赞助是我前进的最大动力！"
        textLabel.textColor = UIColor.darkGray
        view.backgroundColor = UIColor.white
    }

    @IBAction func clickAliPayButton(_ sender: UIButton) {
        let url = URL(string: "HTTPS://QR.ALIPAY.COM/FKX071139IYCKGSXAIXF00")!
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true, completion: nil)
    }

    @IBAction func clickWechatPayButton(_ sender: UIButton) {
        let image = #imageLiteral(resourceName: "WechatPayQR")
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            // we got back an error!
            let ac = UIAlertController(title: "保存失败", message: "最水木无法将微信二维码保存到您的相册，请在设置中允许最水木访问照片。", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "前往设置", style: .default, handler: { (action) in
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            ac.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "保存成功", message: "最水木已经将微信二维码保存到您的相册中，请打开微信扫一扫并从相册中选择刚刚保存的二维码。再次感谢您对最水木的支持！", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "打开微信", style: .default, handler: { (action) in
                UIApplication.shared.openURL(URL(string: "weixin://")!)
            }))
            ac.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel))
            present(ac, animated: true)
        }
    }
}
