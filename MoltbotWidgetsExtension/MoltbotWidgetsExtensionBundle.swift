import WidgetKit
import SwiftUI

@main
struct MoltbotWidgetsExtensionBundle: WidgetBundle {
    var body: some Widget {
        CronJobsWidget()
        HealthWidget()
        UsageWidget()
    }
}
