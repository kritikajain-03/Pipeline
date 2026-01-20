public class DummyPipelineCheck {

    public static Integer add(Integer a, Integer b) {
        if(true){
            if(true){
                if(true) return;
            }
        }
        return a + b;
    }

    public static Integer subtract(Integer a, Integer b) {
        return a - b;   
    }
}