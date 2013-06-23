package test.com.blockwithme.properties.impl;

import java.util.Arrays;
import java.util.TreeSet;

import junit.framework.TestCase;

import com.blockwithme.properties.Filter;
import com.blockwithme.properties.Properties;
import com.blockwithme.properties.impl.LazyGen;
import com.blockwithme.properties.impl.PropertiesImpl;
import com.blockwithme.properties.impl.GraphImpl;

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
        final GraphImpl<Long> root = new GraphImpl<Long>(0L);
        assertSame(root, root.graph());
        assertNull(root.parent());
        assertNull(root.findRaw("..", true));
        assertSame(root, root.findRaw("/", true));
        doTestGlobalLocalKeyes(root, "", "");
        compareKeyes(root);
    }

    public void testDirectChild() {
        final GraphImpl<Long> root = new GraphImpl<Long>(0L);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        doTestGlobalLocalKeyes(child, "/child", "child");

        assertSame(root, child.graph());
        assertSame(root, child.parent());
        assertSame(root, child.findRaw("..", true));
        assertSame(root, child.findRaw("/", true));

        assertSame(child, root.findRaw("child", true));
        assertSame(child, root.findRaw("/child", true));
        assertSame(child, child.findRaw("/child", true));
        assertSame(root, root.findRaw("child/..", true));
        assertSame(child, root.findRaw("child/../child", true));

        compareKeyes(root, "child");
        compareKeyes(child);
    }

    public void testGrandChild() {
        final GraphImpl<Long> root = new GraphImpl<Long>(0L);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        final PropertiesImpl<Long> grandChild = new PropertiesImpl<Long>(child,
                "grandChild");
        doTestGlobalLocalKeyes(grandChild, "/child/grandChild", "grandChild");

        assertSame(root, grandChild.graph());
        assertSame(child, grandChild.parent());
        assertSame(child, grandChild.findRaw("..", true));
        assertSame(root, grandChild.findRaw("/", true));

        assertSame(grandChild, child.findRaw("grandChild", true));
        assertSame(grandChild, root.findRaw("/child/grandChild", true));
        assertSame(grandChild, grandChild.findRaw("/child/grandChild", true));
        assertSame(child, child.findRaw("grandChild/..", true));
        assertSame(grandChild, child.findRaw("grandChild/../grandChild", true));

        compareKeyes(root, "child");
        compareKeyes(child, "grandChild");
        compareKeyes(grandChild);
    }

    public void testProperties() {
        final GraphImpl<Long> root = new GraphImpl<Long>(0L);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        final PropertiesImpl<Long> grandChild = new PropertiesImpl<Long>(child,
                "grandChild");
        root.set(root, "rootProp", true);
        child.set(child, "childProp", 0);
        grandChild.set(grandChild, "grandChildProp", 10.0);
        root.set(root, "rootProp", false, 5L, false);
        child.set(child, "childProp", 10, 10L, false);
        grandChild.set(grandChild, "grandChildProp", 0.0, 20L, false);

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
        root.set(root, "rootProp", true, 5L, false);
        assertEquals(true, root.findRaw("rootProp", true));
    }

    public void testGenerators() {
        final GraphImpl<Long> root = new GraphImpl<Long>(0L);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        final PropertiesImpl<Long> grandChild = new PropertiesImpl<Long>(child,
                "grandChild");
        root.set(root, "rootProp", true);
        grandChild.set(grandChild, "grandChildProp", new LazyGen(
                "com.blockwithme.properties.impl.Link(../../rootProp)"));
        assertEquals(Boolean.TRUE,
                grandChild.find("grandChildProp", Boolean.class));
        // Check non-child Properties replaced by path ...
        root.set(root, "grandChild", grandChild);
        assertSame(grandChild, root.find("grandChild", PropertiesImpl.class));
        assertNotSame(grandChild, root.findRaw("grandChild", false));

        grandChild.set(grandChild, "grandParent", root);
        assertSame(root, grandChild.find("grandParent", PropertiesImpl.class));
        assertNotSame(root, grandChild.findRaw("grandParent", false));
        final PropertiesImpl<Long> grandChild2 = new PropertiesImpl<Long>(
                child, "grandChild2");
        grandChild.set(grandChild, "grandChild2", grandChild2);
        assertSame(grandChild2,
                grandChild.find("grandChild2", PropertiesImpl.class));
        assertNotSame(grandChild2, grandChild.findRaw("grandChild2", false));
    }

    public void testSettersPriority() {
        final GraphImpl<Long> root = new GraphImpl<Long>(0L) {
            @Override
            public boolean lowerPriority(final Properties<Long> setter1,
                    final Properties<Long> setter2) {
                final Integer id1 = setter1.get("id", Integer.class);
                final Integer id2 = setter2.get("id", Integer.class);
                return id1.compareTo(id2) < 0;
            }
        };
        root.set(root, "id", 0);
        final PropertiesImpl<Long> child = new PropertiesImpl<Long>(root,
                "child");
        child.set(child, "id", 1);
        final PropertiesImpl<Long> grandChild = new PropertiesImpl<Long>(child,
                "grandChild");
        grandChild.set(grandChild, "id", 2);
        root.set(root, "rootProp", true);
        assertEquals(Boolean.TRUE, root.find("rootProp", Boolean.class));
        root.set(grandChild, "rootProp", false);
        assertEquals(Boolean.FALSE, root.find("rootProp", Boolean.class));
        // Change ignored because of priority
        root.set(child, "rootProp", true);
        assertEquals(Boolean.FALSE, root.find("rootProp", Boolean.class));
    }

    public void testList() {
        final GraphImpl<Long> root = new GraphImpl<Long>(0L);
        final PropertiesImpl<Long> list = new PropertiesImpl<Long>(root, "list");
        final PropertiesImpl<Long> child1 = new PropertiesImpl<Long>(list,
                list.nextIndex());
        final PropertiesImpl<Long> child2 = new PropertiesImpl<Long>(list,
                list.nextIndex());
        assertEquals("0", child1.localKey());
        assertEquals("1", child2.localKey());
        assertEquals("[0]", list.keysOf(child1).toString());
        assertEquals("[1]", list.keysOf(child2).toString());
        assertTrue(list.contains(child1));
        assertFalse(root.contains(child1));
        assertFalse(list.isEmptyList());
        assertTrue(root.isEmptyList());
        assertEquals("[1]", list.query(new Filter() {
            @Override
            public boolean accept(final String key, final Object value) {
                return value == child2;
            }
        }).toString());
        list.clear(list, null);
        assertTrue(list.isEmptyList());
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