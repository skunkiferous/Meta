package test.com.blockwithme.properties.impl;

import java.util.Arrays;
import java.util.TreeSet;

import junit.framework.TestCase;

import com.blockwithme.properties.impl.LazyGen;
import com.blockwithme.properties.impl.PropertiesImpl;
import com.blockwithme.properties.impl.RootImpl;

/**
 * The class <code>PropertiesImplTest</code> contains tests for the class
 * {@link <code>PropertiesImpl</code>}
 *
 * @pattern JUnit Test Case
 *
 * @generatedBy CodePro at 15.06.13 17:12
 *
 * @author monster
 *
 * @version $Revision$
 */
public class PropertiesImplTest extends TestCase {

    /**
     * Construct new test instance
     *
     * @param name the test name
     */
    public PropertiesImplTest(final String name) {
        super(name);
    }

    private void doTestGlobalLocalKeyes(final PropertiesImpl<?> prop,
            final String globalKey, final String localKey) {
        assertEquals(globalKey, prop.globalKey());
        assertEquals(localKey, prop.localKey());
        assertEquals(globalKey, prop.findRaw("globalKey", true));
        assertEquals(localKey, prop.findRaw("localKey", true));
        assertEquals(localKey, prop.find("localKey", String.class));
        assertEquals(globalKey, prop.find("globalKey", String.class));
        assertEquals(localKey, prop.find("localKey", String.class, null));
        assertEquals(globalKey, prop.find("globalKey", String.class, null));
        assertEquals(localKey, prop.get("localKey", String.class));
        assertEquals(globalKey, prop.get("globalKey", String.class));
        assertNull(prop.find("notthere", String.class));

        boolean failed = false;
        try {
            prop.get("notthere", String.class);
        } catch (final Exception e) {
            failed = true;
        }
        assertTrue(failed);
    }

    private void compareKeyes(final PropertiesImpl<?> prop,
            final String... expected) {
        final TreeSet<String> keyes = new TreeSet<>();
        for (final String key : prop) {
            keyes.add(key);
        }
        assertEquals(new TreeSet<String>(Arrays.asList(expected)), keyes);
    }

    public void testRoot() {
        final RootImpl<Long> root = new RootImpl<Long>(0L);
        assertSame(root, root.root());
        assertNull(root.parent());
        assertNull(root.findRaw("..", true));
        assertSame(root, root.findRaw("/", true));
        doTestGlobalLocalKeyes(root, "", "");
        compareKeyes(root, "globalKey", "localKey");
    }

    public void testDirectChild() {
        final RootImpl<Long> root = new RootImpl<Long>(0L);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        doTestGlobalLocalKeyes(child, "/child", "child");

        assertSame(root, child.root());
        assertSame(root, child.parent());
        assertSame(root, child.findRaw("..", true));
        assertSame(root, child.findRaw("/", true));

        assertSame(child, root.findRaw("child", true));
        assertSame(child, root.findRaw("/child", true));
        assertSame(child, child.findRaw("/child", true));
        assertSame(root, root.findRaw("child/..", true));
        assertSame(child, root.findRaw("child/../child", true));

        compareKeyes(root, "globalKey", "localKey", "child");
        compareKeyes(child, "globalKey", "localKey");
    }

    public void testGrandChild() {
        final RootImpl<Long> root = new RootImpl<Long>(0L);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        final PropertiesImpl<Long> grandChild = new PropertiesImpl<Long>(child,
                "grandChild");
        doTestGlobalLocalKeyes(grandChild, "/child/grandChild", "grandChild");

        assertSame(root, grandChild.root());
        assertSame(child, grandChild.parent());
        assertSame(child, grandChild.findRaw("..", true));
        assertSame(root, grandChild.findRaw("/", true));

        assertSame(grandChild, child.findRaw("grandChild", true));
        assertSame(grandChild, root.findRaw("/child/grandChild", true));
        assertSame(grandChild, grandChild.findRaw("/child/grandChild", true));
        assertSame(child, child.findRaw("grandChild/..", true));
        assertSame(grandChild, child.findRaw("grandChild/../grandChild", true));

        compareKeyes(root, "globalKey", "localKey", "child");
        compareKeyes(child, "globalKey", "localKey", "grandChild");
        compareKeyes(grandChild, "globalKey", "localKey");
    }

    public void testProperties() {
        final RootImpl<Long> root = new RootImpl<Long>(0L);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        final PropertiesImpl<Long> grandChild = new PropertiesImpl<Long>(child,
                "grandChild");
        root.set("rootProp", true, null);
        child.set("childProp", 0, null);
        grandChild.set("grandChildProp", 10.0, null);
        root.set("rootProp", false, 5L);
        child.set("childProp", 10, 10L);
        grandChild.set("grandChildProp", 0.0, 20L);

        assertEquals(true, root.findRaw("rootProp", true));
        assertEquals(true, child.findRaw("../rootProp", true));
        assertEquals(0, child.findRaw("childProp", true));
        assertEquals(0, root.findRaw("child/childProp", true));
        assertEquals(10.0, grandChild.findRaw("grandChildProp", true));
        assertEquals(10.0,
                root.findRaw("/child/grandChild/grandChildProp", true));

        root.setTime(5L);
        assertEquals(false, root.findRaw("rootProp", true));
        assertEquals(0, child.findRaw("childProp", true));
        assertEquals(10.0, grandChild.findRaw("grandChildProp", true));

        root.setTime(25L);
        assertEquals(false, root.findRaw("rootProp", true));
        assertEquals(10, child.findRaw("childProp", true));
        assertEquals(0.0, grandChild.findRaw("grandChildProp", true));

        // Set value in past? Must work directly
        root.set("rootProp", true, 5L);
        assertEquals(true, root.findRaw("rootProp", true));
    }

    public void testGenerators() {
        final RootImpl<Long> root = new RootImpl<Long>(0L);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        final PropertiesImpl<Long> grandChild = new PropertiesImpl<Long>(child,
                "grandChild");
        root.set("rootProp", true, null);
        grandChild.set("grandChildProp", new LazyGen(
                "com.blockwithme.properties.impl.Link(../../rootProp)"), null);
        assertEquals(Boolean.TRUE,
                grandChild.find("grandChildProp", Boolean.class));
        // TODO Test replacement worked
    }
}

/*$CPS$ This comment was generated by CodePro. Do not edit it.
 * patternId = com.instantiations.assist.eclipse.pattern.testCasePattern
 * strategyId = com.instantiations.assist.eclipse.pattern.testCasePattern.junitTestCase
 * additionalTestNames =
 * assertTrue = false
 * callTestMethod = true
 * createMain = false
 * createSetUp = false
 * createTearDown = false
 * createTestFixture = false
 * createTestStubs = false
 * methods =
 * package = test.com.blockwithme.properties.impl
 * package.sourceFolder = Meta/test
 * superclassType = junit.framework.TestCase
 * testCase = PropertiesImplTest
 * testClassType = com.blockwithme.properties.impl.PropertiesImpl
 */