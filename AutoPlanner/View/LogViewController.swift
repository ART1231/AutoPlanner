//
//  LogViewController.swift
//  AutoPlanner
//
//  Created by 荒田大輔 on 2021/07/05.
//

import UIKit
import EventKit

class LogViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showPlan()
    }
    
    @IBOutlet weak var eventshow: UILabel!
    @IBOutlet weak var gaptime: UILabel!
    
    
    @IBAction func planButton(_ sender: Any) {
        self.performSegue(withIdentifier: "toPlanning", sender: self)
    }
    
    
    func showPlan() {
        eventshow.text = ""
        eventshow.numberOfLines = 0
        gaptime.text = ""
        gaptime.numberOfLines = 0
        
        var allEvents: [EKEvent] = []

        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        let useCalendar = Calendar(identifier: .gregorian)
        
        //全てのカレンダーに対して検索
        for calendar in calendars {
            let startDate = useCalendar.startOfDay(for: Date())
            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
            let events = eventStore.events(matching: predicate)
            allEvents.append(contentsOf: events)
        }
        
        allEvents.sort {
            if($0.startDate == $1.startDate){
                return $0.endDate < $1.endDate
            } else {
                return $0.startDate < $1.startDate
            }
        }
        
        if(allEvents.count == 0){
            eventshow.text? = "予定なし \n"
            gaptime.text? = "終日 \n"
        }
        
        else {
            
            let formatTime = DateFormatter()
            formatTime.dateStyle = .short
            formatTime.timeStyle = .short
            formatTime.locale = Locale(identifier: "ja_JP")
            
            let formatDay = DateFormatter()
            formatDay.dateStyle = .short
            formatDay.locale = Locale(identifier: "ja_JP")
            
            //var previousHour = 0
            //var previousMinute = 0
            var allSpareMinute = 0
            
            var formatStartTime:(Int, Int)
            var formatEndTime :(Int, Int) = (0,0)
            var spareTime :Int
            let todayDate = Date()
            var isEventsExist = false
            var isEndCalculation = false
            
            var instantStart:(Int, Int) = (0,0)
            var instantEnd:(Int, Int) = (24,0)

            for event in allEvents {
                if (event.isAllDay == true){
                    eventshow.text?.append( "終日: \(event.title!), in, \(event.calendar.title) \n")
                } else {
                    isEventsExist = true
                    
                    eventshow.text?.append( "\(event.title!), in, \(event.calendar.title) \n")
                    eventshow.text?.append( "Start: \(formatTime.string(from: event.startDate)) \n")
                    eventshow.text?.append( "End: \(formatTime.string(from: event.endDate)) \n")
                    
                    if (isEndCalculation == false){
                        //次の予定の開始時間-対象イベントの終了時間で隙間時間を足す
                        //前日をふくむ予定は配列のどこにあろうが終わり時間だけとる
                        if (formatDay.string(from: todayDate) == formatDay.string(from: event.startDate)) {
                            instantStart = dateToTimeFormat(date: event.startDate)
                            if (compareTime(endHour: formatEndTime.0, endMinute: formatEndTime.1, startHour: instantStart.0, startMinute: instantStart.1)){
                                formatStartTime = instantStart
                                //一回目の代入だけ、０時０分から予定の開始時間を引く
                                spareTime = findSpareTime(startHour: formatEndTime.0, startMinute: formatEndTime.1, endHour: formatStartTime.0, endMinute: formatStartTime.1)
                                allSpareMinute += spareTime
                            }
                        }
                        
                        if(dateToDayFormat(date: event.endDate) != dateToDayFormat(date: todayDate)){
                            isEndCalculation = true
                        } else {
                            instantEnd = dateToTimeFormat(date: event.endDate)
                            if(compareTime(endHour: formatEndTime.0, endMinute: formatEndTime.1, startHour: instantEnd.0, startMinute: instantEnd.1)){
                            formatEndTime = instantEnd
                            }
                        }
                    }
                }
            }
            
            if (isEventsExist == false) {
                gaptime.text?.append("合計 24時間 0分")
            }
            
            else {
                //配列の最後に入っている予定が、翌日以降に回っていない場合、
                //２４時から予定の終了時間を引いて隙間時間を出す
                if(dateToDayFormat(date: todayDate) == dateToDayFormat(date: allEvents.last!.endDate)){
                    spareTime = findSpareTime(startHour: formatEndTime.0, startMinute: formatEndTime.1, endHour: 24, endMinute: 0)
                    allSpareMinute += spareTime
                }
            
                let SpareHour = allSpareMinute / 60
                let SpareMinute = allSpareMinute % 60
                gaptime.text?.append("合計 \(SpareHour)時間 \(SpareMinute) 分")
            }
        }
    }
    

    //Date型の時間だけ取り出す
    func dateToTimeFormat(date: Date) -> (Int, Int) {
        let cal = Calendar.current
        let comp = cal.dateComponents(
            [Calendar.Component.hour, Calendar.Component.minute], from: date)
        return(comp.hour!, comp.minute!)
    }
    
    //Date型の日にちだけ取り出す
    func dateToDayFormat(date: Date) -> (Int) {
        let cal = Calendar.current
        let comp = cal.dateComponents([Calendar.Component.day], from:date)
        return(comp.day!)
    }
    
    //引数に入れた時間の差をとる
    func findSpareTime(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) -> (Int){
        let spareHour = endHour - startHour
        let spareMinute = endMinute - startMinute
        let spareTime = spareHour * 60 + spareMinute
        return (spareTime)
    }
    
    //予定間に隙間時間があった場合、trueを返す
    func compareTime(endHour: Int, endMinute: Int, startHour: Int, startMinute: Int) -> (Bool){
        if (startHour > endHour) {
            return (true)
        } else if (startHour == endHour){
            if (startMinute > endMinute) {
                return (true)
            }
        }
        return (false)
    }
    
}
