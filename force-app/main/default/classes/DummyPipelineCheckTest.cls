@IsTest
public class DummyPipelineCheckTest {

    @IsTest
    static void testAddMethod() {
        Integer result = DummyPipelineCheck.add(5, 3);
        System.assertEquals(8, result, 'Addition result is incorrect');
    }



    hjbhjb
    @IsTest
    static void testSubtractMethod() {
        Integer result = DummyPipelineCheck.subtract(10, 4);
        System.assertEquals(6, result, 'Subtraction result is incorrect');
    }
}