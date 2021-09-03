//
//  AutoPlanViewController.swift
//  AutoPlanner
//
//  Created by 荒田大輔 on 2021/08/05.
//

import UIKit
import EventKit

class AutoPlanViewController: UIViewController, UITextFieldDelegate{
    
    @IBOutlet weak var planName: UITextField!
    @IBOutlet weak var startDate: UIDatePicker!
    @IBOutlet weak var endDate: UIDatePicker!
    @IBOutlet weak var startTime: UIDatePicker!
    @IBOutlet weak var endTime: UIDatePicker!
    @IBOutlet weak var taskAllTime: UIDatePicker!
    
    func setDay(date:Date) -> String{
        let format = DateFormatter()
        format.dateStyle = .short
        format.timeStyle = .none
        format.locale = Locale(identifier: "ja_JP")
        return format.string(from: date)
    }
    
    func setTime(date:Date) -> String{
        let format = DateFormatter()
        format.dateStyle = .none
        format.timeStyle = .short
        format.locale = Locale(identifier: "ja_JP")
        return format.string(from: date)
    }
    
    //func connect(day:Date, time:Date) -> Date{
    //    let stringDate:String = setDay(date: day) + " " + setTime(date: time)
    //    let format = DateFormatter()
    //    format.locale = Locale(identifier: "ja_JP")
    //    format.dateFormat = "yyyy年M月d日 H時m分"
    //    let date = format.date(from: stringDate)
    //    return(date!)
    //}
    
    
    @IBAction func isSetOK(_ sender: Any) {
        print(connect(day: startDate.date, time: startTime.date))
    }
    
    //最初からあるメソッド
    override func viewDidLoad() {
        super.viewDidLoad()
        planName.delegate = self
        
        if #available(iOS 14, *) {
            startDate.preferredDatePickerStyle = .wheels
            endDate.preferredDatePickerStyle = .wheels
            startTime.preferredDatePickerStyle = .wheels
            endTime.preferredDatePickerStyle = .wheels
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        planName.resignFirstResponder()
        return true
    }
    
    func addevent() {
        var eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = planName.text
        //event.startDate =
        
    }
    
}
