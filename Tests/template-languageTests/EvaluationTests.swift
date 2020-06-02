import XCTest
import template_language

final class EvaluationTests: XCTestCase {
    var input: String! = nil
    var parsed: AnnotatedExpression {
        do {
            return try input.parse()
        } catch {
            let p = error as! ParseError
            let lineRange = input.lineRange(for: p.offset..<p.offset)
            print(input[lineRange])
            let dist = input.distance(from: lineRange.lowerBound, to: p.offset)
            print(String(repeating: " ", count: dist) + "^")
            print(p.reason)
            fatalError()
        }
    }
    
    var context: EvaluationContext = EvaluationContext()
    
    override func tearDown() {
        input = nil
        context = EvaluationContext()
    }
    
    var evaluated: TemplateValue {
        do {
            return try context.evaluate(parsed)
        } catch {
            dump(error) // todo
            fatalError()
        }
    }
    

    func testVariable() {
        input = "{ title }"
        context = EvaluationContext(values: ["title": .string("Title")])
        XCTAssertEqual(evaluated, .string("Title"))
    }

    func testTag () {
        input = "<p><span>{bar}</span>{ title }</p>"
        context = EvaluationContext(values: ["title": .string("Title & Foo"), "bar": .string("&")])
        XCTAssertEqual(evaluated, .rawHTML("<p><span>&amp;</span>Title &amp; Foo</p>"))
    }
    
    func testTagWithAttributes() {
        input = "<div id={name}></div>"
        context = EvaluationContext(values: ["name": .string("foo \" bar")])
        XCTAssertEqual(evaluated, .rawHTML("<div id=\"foo &quot; bar\"></div>"))
    }

    func testNonExistentVariable() {
        input = "<p>{ title }</p>"
        XCTAssertThrowsError(try context.evaluate(parsed)) { err in
            let e = err as! EvaluationError
            XCTAssertEqual(e.reason, .variableMissing("title"))
            XCTAssertEqual(e.range, input.range(of: "title"))
        }
    }
}
