public class LoginInsightAnalyzer {

    /**
     * Returns true if login hour is considered business hours (9–18)
     */
    public static Boolean isBusinessHour(Integer hour) {
        if (hour == null) {
            return false;
        }
        return hour >= 9 && hour <= 18;
    }
}
