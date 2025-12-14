//
//  BottlejiLiveActivityWidgetLiveActivity.swift
//  BottlejiLiveActivityWidget
//
//  Created by Yassine Romdhane on 14.12.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BottlejiLiveActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BottlejiLiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BottlejiLiveActivityWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension BottlejiLiveActivityWidgetAttributes {
    fileprivate static var preview: BottlejiLiveActivityWidgetAttributes {
        BottlejiLiveActivityWidgetAttributes(name: "World")
    }
}

extension BottlejiLiveActivityWidgetAttributes.ContentState {
    fileprivate static var smiley: BottlejiLiveActivityWidgetAttributes.ContentState {
        BottlejiLiveActivityWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BottlejiLiveActivityWidgetAttributes.ContentState {
         BottlejiLiveActivityWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BottlejiLiveActivityWidgetAttributes.preview) {
   BottlejiLiveActivityWidgetLiveActivity()
} contentStates: {
    BottlejiLiveActivityWidgetAttributes.ContentState.smiley
    BottlejiLiveActivityWidgetAttributes.ContentState.starEyes
}
