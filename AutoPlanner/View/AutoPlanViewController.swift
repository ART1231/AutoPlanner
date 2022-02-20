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
    
    var calendarIdentifier:[String]! = []
    var keyWord:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        planName.delegate = self
        
        let now:Date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let zeroDate:Date = calendar.date(from: DateComponents(hour:hour, minute: 0))!
        startTime.date = zeroDate
        endTime.date = zeroDate
        
        if #available(iOS 14, *) {
            startDate.preferredDatePickerStyle = .wheels
            endDate.preferredDatePickerStyle = .wheels
            startTime.preferredDatePickerStyle = .wheels
            endTime.preferredDatePickerStyle = .wheels
        }
        
        //タップされた時にテキストフィールドを隠すための記述
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGR.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGR)
        
    }
    
    //returnボタンをおしたら入力終了
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    //datepickerで日にちだけをString型で抽出する
    func setDay(date:Date) -> String{
        let format = DateFormatter()
        format.dateStyle = .short
        format.timeStyle = .none
        format.locale = Locale(identifier: "ja_JP")
        return format.string(from: date)
    }
    
    //datepickerで時間だけをString型で抽出する
    func setTime(date:Date) -> String{
        let format = DateFormatter()
        format.dateStyle = .none
        format.timeStyle = .short
        format.locale = Locale(identifier: "ja_JP")
        return format.string(from: date)
    }
    
    //Date型の日付と時間を連結させる
    //returnはDate型
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
    
    //「設定完了」を押した後に表示される確認画面
    @IBAction func isSetOK(_ sender: Any) {
        let alertController = UIAlertController(title: "確認", message: "保存してよろしいでしょうか", preferredStyle: .alert )
        let okAction = UIAlertAction(title: "保存", style: .default, handler: {(action: UIAlertAction!) in
            self.addTask()
        })
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: {(action: UIAlertAction!) in })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)

    }
   
    // 開始時間が終了時間より後にあった場合のエラー表示
    func errorTimeAlert() {
        let alert = UIAlertController(title: "エラー", message: "開始日時が終了日時の後になっています", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    

    
    //　指定された期間の同じ時間にタスクを追加し続ける
    func addTask() {
        let calendar = Calendar.current
        var setDate:Date = startDate.date
        let startDateTime = connect(day: setDate, time: startTime.date)
        let endDateTime = connect(day: endDate.date, time: endTime.date)
        
        var allTaskTime = 0
        keyWord = (planName.text! + setDay(date: startDate.date) + setDay(date: endDate.date) + setTime(date: startTime.date) + setTime(date: endTime.date))
        
        //被せる可能性がある日だけをピックアップ
        var pickEvents: [EKEvent] = []
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        
        //全てのカレンダーに対して検索
        for calendar in calendars {
            let startDate = startDateTime
            let endDate = endDateTime
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
            let events = eventStore.events(matching: predicate)
            pickEvents.append(contentsOf: events)
        }
        
        pickEvents.sort {
            if($0.startDate == $1.startDate){
                return $0.endDate < $1.endDate
            } else {
                return $0.startDate < $1.startDate
            }
        }
        
        
        if(startDateTime > endDateTime){
                errorTimeAlert()
        } else {
            while(true){
                whichAddEvent()
                if(setDay(date: setDate) == setDay(date: endDate.date)){
                    break
                } else {
                    setDate = calendar.date(byAdding: .day, value: 1, to: setDate)!
                }
            }
        }
        
        
        //純正カレンダーに追加するためのメソッド
        func addevent(date:Date) {
            let eventStore = EKEventStore()
            let event = EKEvent(eventStore: eventStore)
            event.title = planName.text
            event.startDate = connect(day: date, time:startTime.date)
            event.endDate = connect(day: date, time:endTime.date)
            event.calendar = eventStore.defaultCalendarForNewEvents
            allTaskTime += Int(event.endDate.timeIntervalSince(event.startDate))
            print(allTaskTime)
            
            do {
                try eventStore.save(event, span: .thisEvent)
                calendarIdentifier.append(event.eventIdentifier)
            } catch {
                let nserror = error as NSError
                print("addevent")
                print(nserror)
            }
        }
        
        //予定が重なってるときのタスク追加
        func addExceptionEvent(startDate:Date, endDate:Date) {
            let eventStore = EKEventStore()
            let event = EKEvent(eventStore: eventStore)
            event.title = planName.text
            event.startDate = startDate
            event.endDate = endDate
            event.calendar = eventStore.defaultCalendarForNewEvents
            allTaskTime += Int(event.endDate.timeIntervalSince(event.startDate))
            
            do {
                try eventStore.save(event, span: .thisEvent)
                calendarIdentifier.append(event.eventIdentifier)
            } catch {
                let nserror = error as NSError
                print("addExceptionEvent")
                print(nserror)
            }
        }
        
        // Int型で集計したタスク合計時間を, 〇〇時間〇〇分のString型で返す
        func timeChange(time:Int) -> String{
            let hours:Int = time/3600
            let minutes:Int = time%3600/60
            return("\(hours) 時間 \(minutes) 分")
        }
        
        //UserDefaultsを用いてTask画面に設定内容を保存する
        func setglobal() {
            var taskArray:[[String]] = UserDefaults.standard.array(forKey: "tasks") as? [[String]] ?? [[String]]()
            let taskInfo:[String] = [planName.text!, setDay(date: startDate.date), setDay(date: endDate.date), setTime(date: startTime.date), setTime(date: endTime.date), timeChange(time: allTaskTime)]
            taskArray.append(taskInfo)
            UserDefaults.standard.set(taskArray, forKey: "tasks")
            UserDefaults.standard.set(calendarIdentifier, forKey: keyWord)
            
        }
        
        //　重なりそうな場合は回避し, 問題なければそのまま追加する
        func whichAddEvent() {
            var temStartDateTime = connect(day: setDate, time: startTime.date)
            var setStartTime = temStartDateTime
            var temEndDateTime = connect(day: setDate, time: endTime.date)
            let setEndTime = temEndDateTime
            var isadd = false
            var isend = false
            
            for events in pickEvents {
                if (events.isAllDay != true) {
                    if (events.startDate.compare(setStartTime) == .orderedDescending) {
                        if(events.startDate.compare(setEndTime) != .orderedDescending) {
                            //前を詰める
                            temEndDateTime = connect(day: setDate, time: events.startDate)
                            addExceptionEvent(startDate: temStartDateTime, endDate: temEndDateTime)
                            isadd = true
                            //eventsの終わり時間が追加対象範囲を超えている場合は終了
                            if(events.endDate.compare(setEndTime) == .orderedAscending) {
                                temStartDateTime = events.endDate
                                setStartTime = events.startDate
                            } else {
                                isend = true
                                break
                            }
                        }
                    } else {
                        if(events.endDate.compare(setStartTime) == .orderedDescending) {
                            if(events.endDate.compare(setEndTime) == .orderedAscending) {
                                temStartDateTime = events.endDate
                                isadd = true
                            } else {
                                isadd = true
                                isend = true
                                break
                            }
                        }
                    }
                }
            }
            
            if (isadd == false) {
                addevent(date: setDate)
            } else if (isend == false) {
                addExceptionEvent(startDate: temStartDateTime, endDate: setEndTime)
            }
        }
        setglobal()
        calendarIdentifier.removeAll()
        self.navigationController?.popViewController(animated: true)
    }

}
