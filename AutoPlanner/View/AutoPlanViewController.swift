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
    
    func connect(day:Date, time:Date) -> Date{
        let stringDate:String = setDay(date: day) + " " + setTime(date: time)
        let format = DateFormatter()
        format.locale = Locale(identifier: "ja_JP")
        format.timeZone = TimeZone(identifier: "Asia/Tokyo")
        format.dateFormat = "yyyy/MM/dd HH:mm"
        if let date:Date = format.date(from: stringDate){
            return date
        } else{
            return day
        }
    }
    
    
    @IBAction func isSetOK(_ sender: Any) {
        let alertController = UIAlertController(title: "確認", message: "保存してよろしいでしょうか", preferredStyle: .alert )
        let okAction = UIAlertAction(title: "保存", style: .default, handler: {(action: UIAlertAction!) in
            self.navigationController?.popViewController(animated: true)
        })
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: {(action: UIAlertAction!) in })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)

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
    
    func addevent(date:Date) {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = planName.text
        event.startDate = connect(day:date, time:startTime.date)
        event.endDate = connect(day: date, time:endTime.date)
        event.calendar = eventStore.defaultCalendarForNewEvents
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            let nserror = error as NSError
            print(nserror)
        }
    }
    
    func addTask() {
        let calendar = Calendar.current
        var setDate:Date = startDate.date
        
        if(setDate == endDate.date){
            addevent(date: setDate)
        } else {
            while(setDate != endDate.date){
                addevent(date: setDate)
                setDate = calendar.date(byAdding: .day, value: 1, to: setDate)!
            }
        }
        
        self.navigationController?.popViewController(animated: true)
    }
}
