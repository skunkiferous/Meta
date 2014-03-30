/*
 * Copyright (C) 2014 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta

import com.blockwithme.meta.converter.BooleanConverter
import com.blockwithme.meta.converter.ByteConverter
import com.blockwithme.meta.converter.CharConverter
import com.blockwithme.meta.converter.Converter
import com.blockwithme.meta.converter.DoubleConverter
import com.blockwithme.meta.converter.FloatConverter
import com.blockwithme.meta.converter.IntConverter
import com.blockwithme.meta.converter.LongConverter
import com.blockwithme.meta.converter.ShortConverter
import com.blockwithme.util.Footprint
import java.io.Serializable
import java.util.Collections
import java.util.Map
import java.util.TreeSet
import org.slf4j.LoggerFactory

import static com.blockwithme.util.Preconditions.*
import static com.blockwithme.traits.util.SyncUtil.*
import static java.util.Objects.*
import com.blockwithme.fn1.ObjectFuncObject
import com.blockwithme.fn2.ObjectFuncObjectObject
import com.blockwithme.fn1.BooleanFuncObject
import com.blockwithme.fn2.ObjectFuncObjectBoolean
import com.blockwithme.fn1.ByteFuncObject
import com.blockwithme.fn2.ObjectFuncObjectByte
import com.blockwithme.fn1.CharFuncObject
import com.blockwithme.fn2.ObjectFuncObjectChar
import com.blockwithme.fn1.ShortFuncObject
import com.blockwithme.fn2.ObjectFuncObjectShort
import com.blockwithme.fn2.ObjectFuncObjectInt
import com.blockwithme.fn1.IntFuncObject
import com.blockwithme.fn2.ObjectFuncObjectFloat
import com.blockwithme.fn1.FloatFuncObject
import com.blockwithme.fn1.LongFuncObject
import com.blockwithme.fn2.ObjectFuncObjectLong
import com.blockwithme.fn1.DoubleFuncObject
import com.blockwithme.fn2.ObjectFuncObjectDouble
import de.oehme.xtend.contrib.Volatile
import java.util.HashMap
import java.util.HashSet
import java.util.Set
import java.util.concurrent.atomic.AtomicReference
import java.util.Arrays
import javax.inject.Provider
import com.blockwithme.meta.beans.Bean
import java.lang.reflect.Array
import java.util.Collection
import java.util.List
import java.util.ArrayList
import java.util.Iterator
import java.util.Objects

/**
 * Hierarchy represents a Type hierarchy. It is not limited to types in the
 * same package or module/jar, but typically, types coming from other
 * module/jars, or even maybe from other packages, would have their own
 * (partial) hierarchy, and the hierarchy of types farther away from the root
 * would depends on hierarchies nearer the root.
 *
 * The Hierarchy instance should be created like this:
 *     public final static Hierarchy HIERARCHY = Hierarchy.postCreateHierarchy(new Hierarchy(...));
 * To make sure it is correctly registered.
 *
 * It is totally possibly for the same Java class to belong to more then one
 * Hierarchy (but they should not depend on each other).
 *
 * Since, unfortunately, some information cannot be recorded as final fields
 * during initialization, we need to use synchronization to make the access
 * thread-safe. The Hierarchy instance plays the role of the "lock".
 *
 * @author monster
 */
public class Hierarchy implements Comparable<Hierarchy> {
    private static val LOG = LoggerFactory.getLogger(Hierarchy)

    /** All the Hierarchies */
    static var all = <Hierarchy>newArrayOfSize(0)

    /** All Listeners. */
    static val listeners = <HierarchyListener>newArrayList()

    /** The zero-based Hierarchy ID */
    public val int hierarchyId

    /** The Hierarchy name */
    public val String name

	/**
	 * The dependencies of the Hierarchy, if any.
	 * Do not modify!
	 */
	public val Hierarchy[] dependencies

	/** All types of this hierarchy */
	public val Type<?>[] allTypes

	/** All properties of this hierarchy */
	public val Property<?,?>[] allProperties

	/** All packages of this hierarchy */
	public val TypePackage[] allPackages

	/** Quick access to Type instances by name */
	var Map<String,Type<?>> allTypesByName

	/** The depth of the Hierarchy. */
	public val int depth

    /** All the *currently initialized* Hierarchies */
    static def getHierarchies() {
		synchR(Hierarchy) [
			all
		]
    }

    /** Adds a HierarchyListener */
    static def void addListener(HierarchyListener listener) {
		synch(Hierarchy) [
	        if (listeners.contains(requireNonNull(listener, "listener"))) {
	            throw new IllegalArgumentException("Cannot add a listener more then once!");
	        }
	        listeners.add(listener);
	        for (h : all) {
	        	postCreateHierarchy(h, listener)
	        }
	        val metas = Meta.BUILDER.allProperties()
	    	for (m : metas) {
	    		postCreateMetaProperty(m as MetaProperty<?,?>, listener)
	    	}
    	]
    }

    /** Removes a HierarchyListener */
    static def void removeListener(HierarchyListener listener) {
		synch(Hierarchy) [
	        listeners.remove(requireNonNull(listener, "listener"))
    	]
    }

    /**
     * Called on a Hierarchy, after it has been fully registered and initialized.
     * (Initialization of the subclasses happens *after* registration).
     */
    package static def postCreateHierarchy(Hierarchy hierarchy) {
    	requireNonNull(hierarchy, "hierarchy")
		for (p : hierarchy.allPackages) {
			LOG.info("Setting Hierarchy "+hierarchy+" in Package "+p)
			p.hierarchy = hierarchy
		}
        for (listener : listeners) {
        	postCreateHierarchy(hierarchy, listener)
        }
    }

    /**
     * Called on a Hierarchy, after it has been fully registered and initialized.
     * (Initialization of the subclasses happens *after* registration).
     */
    package static def postCreateHierarchy(Hierarchy hierarchy, HierarchyListener listener) {
    	try {
    		listener.onNewHierarchy(hierarchy)
		} catch(RuntimeException e) {
			LOG.error("Got error calling "+listener.class.name+".onNewHierarchy("+hierarchy+")", e)
		} catch(Error e) {
			LOG.error("Got error calling "+listener.class.name+".onNewHierarchy("+hierarchy+")", e)
		}
    	for (type : hierarchy.allTypes) {
	    	try {
	    		listener.onNewType(type)
			} catch(RuntimeException e) {
				LOG.error("Got error calling "+listener.class.name+".onNewType("+type+")", e)
			} catch(Error e) {
				LOG.error("Got error calling "+listener.class.name+".onNewType("+type+")", e)
			}
    	}
    }

    /**
     * Called on a MetaProperty, after it has been fully registered and initialized.
     * (Initialization of the subclasses happens *after* registration).
     */
    package static def postCreateMetaProperty(
    	MetaProperty<?,?> metaProperty, HierarchyListener listener) {
	    	try {
	    		listener.onNewMetaProperty(metaProperty)
			} catch(RuntimeException e) {
				LOG.error("Got error calling "+listener.class.name+".onNewMetaProperty("+metaProperty+")", e)
			} catch(Error e) {
				LOG.error("Got error calling "+listener.class.name+".onNewMetaProperty("+metaProperty+")", e)
			}
    }

    /**
     * Called on a MetaProperty, after it has been fully registered and initialized.
     * (Initialization of the subclasses happens *after* registration).
     */
    static def <M extends MetaProperty<?,?>> postCreateMetaProperty(M metaProperty) {
    	synch(Hierarchy) [
    		Meta.BUILDER.doRegisterProperty(metaProperty)
	        for (listener : listeners) {
	        	postCreateMetaProperty(metaProperty, listener)
	        }
        ]
        metaProperty
    }

    /** Sets the value of this property, as an Object */
    static def setObject(MetaBase<?> object, int index, Object value) {
		synch(Hierarchy) [
            var array = object.metaProperties;
            if (index >= array.length) {
                val tmp = newArrayOfSize(index + 1)
                System.arraycopy(array, 0, tmp, 0, array.length);
                array = object.metaProperties = tmp;
            }
            array.set(index, value)
    	]
    }


	/**
	 * Creates a hierarchy. If we have dependencies, theBase should usually
	 * come from one of them, possibly indirectly.
	 */
	private new(String theName, TypePackage[] thePackages, Type<?>[] theTypes,
		Property<?,?>[] theProperties,  Hierarchy[] theDependencies) {
		name = requireNonEmpty(theName, "theName")
		allTypes = requireContainsNoNull(theTypes, "theTypes")
		allProperties = requireContainsNoNull(theProperties, "theProperties")
		allPackages = requireContainsNoNull(thePackages, "thePackages")
		dependencies = requireContainsNoNull(theDependencies, "theDependencies")
		if ((thePackages.length == 0) && (theDependencies.length == 0)) {
			throw new IllegalArgumentException("Empty Hierarchy not supported")
		}
		hierarchyId = synchR(Hierarchy) [
			val tmp = newArrayList(all)
			tmp.add(this)
			all = tmp
			all.length
    	]
    	depth = if (!dependencies.empty) {
    		var d = 0
	    	for (dep : dependencies) {
	    		val dd = dep.depth
	    		if (dd > d) {
	    			d = dd
	    		}
	    	}
	    	d + 1
    	} else {
    		0
    	}
    	synch(Hierarchy) [
			// OK, there is some chances, that the class of this Hierarchy
			// actually extends this class, and that we are not fully
			// initialized!
			postCreateHierarchy(this)
    	]
	}

	protected new (HierarchyBuilder builder, TypePackage[] packages, Hierarchy ... theDependencies) {
		this(requireNonNull(builder, "builder").name, builder.registerPackage(packages),
			builder.allTypes(), builder.allProperties(), theDependencies)
		builder.close()
	}

    protected new (HierarchyBuilder builder, Hierarchy ... theDependencies) {
        this(builder, newArrayOfSize(0), theDependencies)
    }

    protected new (HierarchyBuilder builder, TypePackage... packages) {
        this(builder, packages, newArrayOfSize(0))
    }

    protected new (HierarchyBuilder builder) {
         this(builder, newArrayOfSize(0), newArrayOfSize(0))
    }

	override final toString() {
		name
	}

	/** Quick access to Type instances by name */
	private final def getAllTypesByName() {
		if (allTypesByName === null) {
			val map = new HashMap<String,Type<?>>()
			for (t : allTypes) {
				map.put(t.fullName, t)
			}
			allTypesByName = map
		}
		allTypesByName
	}

	/**
	 * Searches for a Type by name.
	 * Also delegates to dependencies.
	 */
	final def Type<?> findType(String name) {
		findType(requireNonEmpty(name, "name"), new HashSet<Hierarchy>())
	}

	/** Searches for a Type by name */
	private final def Type<?> findType(String name, Set<Hierarchy> checked) {
		var result = getAllTypesByName().get(name)
		if (result === null) {
			for (h : dependencies) {
				if (checked.add(h)) {
					result = h.findType(name, checked)
					if (result !== null) {
						return result
					}
				}
			}
		}
		result
	}

	/**
	 * Searches for a Type by Class.
	 * Also delegates to dependencies.
	 */
	final def <E> Type<E> findType(Class<E> clazz) {
		findType(requireNonNull(clazz, "clazz").name, new HashSet<Hierarchy>()) as Type<E>
	}

	/**
	 * Searches for a Type by Class.
	 * Does not delegate to dependencies.
	 */
	final def <E> Type<E> findTypeDirect(Class<E> clazz) {
		getAllTypesByName().get(requireNonNull(clazz, "clazz").name) as Type<E>
	}

	override int compareTo(Hierarchy o) {
		if (o === null) {
			return 1
		}
		if (o.depth === depth) {
			name.compareTo(o.name)
		} else {
			depth - o.depth
		}
	}

}

/** Hierarchy event listener interface */
interface HierarchyListener {
	/** Called, when a new Hierarchy is created. */
	def void onNewHierarchy(Hierarchy newHierarchy)
	/** Called, when a new Type is created (check the type, for the new Properties). */
	def void onNewType(Type<?> newType)
	/** Called, when a new meta-property is created. */
	def void onNewMetaProperty(MetaProperty<?,?> newMetaProp)
}

/**
 * Base class for Types, Properties, ... all the meta-info objects.
 *
 * It allows the implementation of a system of meta-properties, where
 * a meta-property can be defined anywhere, and read/written from
 * any subclass of MetaBase. This allows, among other things, to add
 * additional "properties" to instances to Type of Property, which
 * were defined and initialized in a third-party jar/module.
 *
 * @author monster
 */
abstract class MetaBase<PARENT> implements Comparable<MetaBase<?>> {
    private static val LOG = LoggerFactory.getLogger(MetaBase)
	/** The full name */
	public val String fullName
	/** The simple name (the part after the last '.' in the full name) */
	public val String simpleName
	/** The zero-based global meta ID, within the Hierarchy */
	public val int globalId
	/** The cached toString */
	private var String toString

    /** Meta-properties values. */
    @Volatile
    package var Object[] metaProperties = newArrayOfSize(0)
    /** Parent object. */
    @Volatile
    package var PARENT parent
    /** Hierarchy */
    @Volatile
    package var Hierarchy hierarchy

	/** Checks no null is in array */
	protected static def <E> E[] checkArray(E[] array, String name) {
		requireNonNull(array, "name")
		if (array.contains(null)) {
			throw new NullPointerException(name+" content")
		}
		array
	}

	/** Constructor */
	package new(String theFullName, String theSimpleName, int theGlobalId) {
		fullName = requireNonNull(theFullName, "theFullName")
		simpleName = requireNonNull(theSimpleName, "theSimpleName")
		if (!theFullName.equals(theSimpleName) &&
			!theFullName.endsWith("."+theSimpleName)) {
			throw new IllegalArgumentException("theFullName("+theFullName
				+") and theSimpleName("+theSimpleName+") do not match!")
		}
		globalId = theGlobalId
		LOG.debug(class.name+"("+fullName+") created with globalId: "+globalId)
	}

	/** toString */
	override final toString() {
		// toString is generated on-demand, since we should not call
		// virtual methods from the constructor...
		if (toString == null) {
			toString = genToString()
		}
		toString
	}

	/** Generates the toString String */
	protected def genToString() { fullName }

	/** Compares to others based on the full name */
	override final int compareTo(MetaBase<?> base) {
		if (base == null) 1 else fullName.compareTo(base.fullName)
	}

    /** The Hierarchy */
    def final Hierarchy hierarchy() {
    	if (hierarchy == null) {
    		if (parent instanceof MetaBase<?>) {
	    		hierarchy = (parent as MetaBase<?>).hierarchy()
	    	}
	    	if (hierarchy == null) {
	    		// Fail!
	    		val prt = if (parent === null) "null" else parent.class.name+" "+parent
	    		throw new IllegalStateException(class.name+" "+fullName+": hierarchy is null; parent="+prt)
	    	}
	    	requireNonNull(hierarchy, "hierarchy")
    	}
    	hierarchy
    }
}

/** Used for Type instance configuration */
package class TypeRegistration {
	/** The hierarchy builder */
	public var HierarchyBuilder builder
	/** The type id in the hierarchy */
	public var int typeId
	/** The global meta id in the hierarchy */
	public var int globalId
}


/** Defines the basic type of a Property */
enum PropertyType {
	BOOLEAN, BYTE, CHARACTER, SHORT, INTEGER, LONG, FLOAT, DOUBLE, OBJECT
}

/**
 * Used for Property instance configuration.
 *
 * OWNER_TYPE is the type that "owns" (contains) the property.
 * Converters are used to convert primitive properties to/from objects
 */
@Data
package class PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<PROPERTY_TYPE>> {
	/** The hierarchy */
	HierarchyBuilder builder
	/**
	 * The owner type. The Type<?> instance gets created *after* the
	 * properties, so we use a Class<?> instead
	 */
	Class<OWNER_TYPE> owner
	String simpleName
	CONVERTER converter
	PropertyType type
	boolean meta
	/** Does this represent a "virtual" property? */
	boolean virtual
	Class<PROPERTY_TYPE> dataType
	/** Special; normally null element 0. Used by meta-properties */
	Type<OWNER_TYPE>[] ownerType = <Type>newArrayOfSize(1)

	int globalId
	int globalPropertyId
	int propertyId
	int specificTypePropId
	int virtualPropertyId
	// For primitive properties
	int bits
	int primitivePropertyId
	int nonSixtyFourBitPropertyId
	int sixtyFourBitPropertyId
	int nonLongPropertyId
	// For Long and Object
	int longOrObjectPropertyId
}

/**
 * Interface implemented by classes that are aware of their own Type.
 */
interface Typed<JAVA_TYPE> {
	/** Returns the Type of this instance */
	def Type<JAVA_TYPE> getType()
}

/** Dummy constructor object */
package class NoConstructor<JAVA_TYPE> implements Provider<JAVA_TYPE> {
	val String type
	new(String theTypeName) {
		type = requireNonNull(theTypeName, "theTypeName")
	}
	new(Class<JAVA_TYPE> theType) {
		type = requireNonNull(theType, "theType").name
	}
	override get() {
		throw new UnsupportedOperationException("Instances of type "+type
			+" cannot be created (without parameters?)")
	}
}


/**
 * Represents a Type. Since we expect to define types with
 * interfaces, multiple inheritance is possible, and therefore
 * we can have any number of parents.
 *
 * The Type instance should be created like this:
 *     public final static Type<XXX> TYPE = Hierarchy.postCreateType(new Type(...));
 * or like this, if you use a sub-class:
 *     public final static MyType TYPE = Hierarchy.postCreateType(new MyType(...));
 * To make sure it is correctly registered.
 *
 * The Type<?> instance gets created *after* the properties, and takes
 * these as parameters. This chicken-and-egg problem means that the type
 * reference in the Property cannot be final.
 *
 * Note that the Type instance does NOT validate the correctness of the
 * "parents" array, by design. The Type instance might not need to define
 * some actual parents (say, if they are only there for technical reasons,
 * and do not belong in the domain). It would also be possible to specify
 * non-existent parents, although there seems to be little use for that.
 *
 * In fact, it should be possible to define Types and Properties representing
 * a dynamic/generic type, with no actual specific Java Class implementing it.
 *
 * There is no requirement that the Type instance be a static constant in
 * the actual type class/interface. This is also by design, to allow Types
 * to be defined for third-party classes.
 *
 * theConstructor can be null, in which case the create method will fail.
 *
 * @author monster
 */
class Type<JAVA_TYPE> extends MetaBase<TypePackage> {

	/** When a Type has no parents */
	public static val Type<?>[] NO_TYPE = <Type>newArrayOfSize(0)

	/** The index of the VALUE component type */
	public static val VALUE_COMPONENT = 0

	/** The index of the KEY component type */
	public static val KEY_COMPONENT = 1

	/** The index of the "generic" third component type */
	public static val THIRD_COMPONENT = 3

	/** Helper to detect primitive wrappers. */
	package static val primTypes = newHashSet(
		Boolean, Byte, Character, Short, Integer, Long, Float, Double)

	/** The Java Class represented by this type. */
	// TODO Allow fully generic types (no Class?)
	public val Class<JAVA_TYPE> type

	/** The empty array of "type" */
	public val JAVA_TYPE[] empty

	/** Does this type represents a primitive/primitive-wrapper type? */
	public val boolean primitive

	/**
	 * The direct parent Types of this Type
	 * Do not modify!
	 */
	public val Type<?>[] parents

	/**
	 * All the direct and inherited parent Types of this Type, recursively.
	 * Do not modify!
	 */
	public val Type<?>[] inheritedParents

	/**
	 * The direct Properties (*without* the virtual properties)
	 * Do not modify!
	 */
	public val Property<JAVA_TYPE,?>[] properties

	/**
	 * The direct Object Properties
	 * Do not modify!
	 */
	public val ObjectProperty<JAVA_TYPE,?>[] objectProperties

	/**
	 * The direct Primitive Properties
	 * Do not modify!
	 */
	public val PrimitiveProperty<JAVA_TYPE,?,?>[] primitiveProperties

	/**
	 * The direct virtual Properties
	 * Do not modify!
	 */
	public val Property<JAVA_TYPE,?>[] virtualProperties

	/**
	 * The properties of this type, and all it's parents (*without* the virtual properties)
	 * Do not modify!
	 */
	public val Property<?,?>[] inheritedProperties

	/**
	 * The Object properties of this type, and all it's parents
	 * Do not modify!
	 */
	public val ObjectProperty<JAVA_TYPE,?>[] inheritedObjectProperties

	/**
	 * The Primitive properties of this type, and all it's parents
	 * Do not modify!
	 */
	public val PrimitiveProperty<JAVA_TYPE,?,?>[] inheritedPrimitiveProperties

	/**
	 * The virtual properties of this type, and all it's parents
	 * Do not modify!
	 */
	public val Property<JAVA_TYPE,?>[] inheritedVirtualProperties

	/**
	 * The Properties returning the generic Types of the "components" of this Type:
	 *
	 * VALUE_COMPONENT for array, collection, map
	 * KEY_COMPONENT for map
	 * THIRD_COMPONENT for (triplet?)
	 *
	 * Note that some of those properties might belong to super-types.
	 *
	 * Do not modify!
	 */
	public val ObjectProperty<JAVA_TYPE,Type<?>>[] componentTypes

	/** The zero-based type ID */
	public val int typeId

	/** The direct primitive property bits total */
	public val int primitivePropertyBitsTotal

	/** The direct primitive property (non-packed) bytes total */
	public val int primitivePropertyByteTotal

	/** The direct primitive property count */
	public val int primitivePropertyCount

	/** The direct object property count */
	public val int objectPropertyCount

	/** The direct virtual property count */
	public val int virtualPropertyCount

	/** The direct property count (*without* the virtual properties) */
	public val int propertyCount

	/** The direct 64-bit primitive property count */
	public val int sixtyFourBitPropertyCount

	/** The direct non-64-bit primitive property count */
	public val int nonSixtyFourBitPropertyCount

	/** The direct boolean primitive property count */
	public val int booleanPrimitivePropertyCount

	/** The direct byte primitive property count */
	public val int bytePrimitivePropertyCount

	/** The direct char primitive property count */
	public val int charPrimitivePropertyCount

	/** The direct short primitive property count */
	public val int shortPrimitivePropertyCount

	/** The direct int primitive property count */
	public val int intPrimitivePropertyCount

	/** The direct long primitive property count */
	public val int longPrimitivePropertyCount

	/** The direct float primitive property count */
	public val int floatPrimitivePropertyCount

	/** The direct double primitive property count */
	public val int doublePrimitivePropertyCount

	/** The direct non-long primitive property count */
	public val int nonLongPrimitivePropertyCount

	/** The inherited property count (*without* the virtual properties) */
	public val int inheritedPropertyCount

	/** Shallow own footprint, without Object overhead */
	public val int footprint

	/** Shallow total footprint, with Object overhead */
	public val int inheritedFootprint

	/** Map *all* property name to property (immutable) */
	public val Map<String,Property<?,?>> simpleNameToProperty

    /** The kind of type, that this class/interface is. */
    public val Kind kind

    /** The default builder instance */
    public val Provider<JAVA_TYPE> constructor

	/** Creates and returns a "fake Provider" for abstract types. */
	private static def <JAVA_TYPE> Provider<JAVA_TYPE> asProvider(Class<JAVA_TYPE> theType) {
		val NoConstructor<JAVA_TYPE> tmp = new NoConstructor<JAVA_TYPE>(theType)
		tmp as Provider<JAVA_TYPE>
	}

	/** Constructor */
	protected new(TypeRegistration registration, Class<JAVA_TYPE> theType,
		Provider<JAVA_TYPE> theConstructor, Kind theKind,
		Type<?>[] theParents, Property<JAVA_TYPE,?>[] theProperties,
		ObjectProperty<JAVA_TYPE,Type<?>>[] componentTypes) {
		super(requireNonNull(theType, "theType").name,
			theType.simpleName, requireNonNull(registration, "registration").globalId)
		if (theType.primitive) {
			throw new IllegalArgumentException("Primitive TYPE "
				+theType+" not supported; use the Wrapper instead")
		}
		primitive = primTypes.contains(theType)
		type = theType
		empty = Array.newInstance(type, 0) as JAVA_TYPE[]
		constructor = if (theConstructor == null) asProvider(theType) else theConstructor
		kind = requireNonNull(theKind, "theKind")
		// componentTypes *can* contain null. This just mean the type is "unknown"
		this.componentTypes = requireNonNull(componentTypes, "componentTypes")
		val TreeSet<Type<?>> pset = new TreeSet(checkArray(theParents, "theParents"))
		val TreeSet<Type<?>> pallset = new TreeSet(pset)
		for (p : pset) {
			pallset.addAll(Arrays.asList(p.inheritedParents))
		}
		// Since we decided NOT to inherit the JAVA Hierarchy by default,
		// we cannot assume that it is inherited. And since OBJECT is in
		// the JAVA Hierarchy, we cannot inherit OBJECT as parent by default.
		// Not sure yet if this is the right thing to do.
		inheritedParents = pallset

		if (type !== Iterable) {
			var iterable = false
			for (p : inheritedParents) {
				if (p.type === Iterable) {
					iterable = true
				}
			}
			if (iterable && componentTypes.empty) {
				throw new IllegalStateException("Types extending Iterable must have at least one component type!")
			}
		}

		// Eliminate direct parents that we also get indirectly ...
		// 1: Remove direct parents from pallset
		for (p : pset) {
			pallset.remove(p)
		}
		// 2: Re-add anything that comes from an indirect parent
		for (p : <Type>newArrayList(pallset)) {
			pallset.addAll(Arrays.asList(p.inheritedParents))
		}
		// 3: Remove from direct parents all the indirect parents
		for (p : <Type>newArrayList(pset)) {
			if (pallset.contains(p)) {
				pset.remove(p)
			}
		}
		parents = pset

		val TreeSet<Property<JAVA_TYPE,?>> ownset = new TreeSet([a,b|
			val MetaBase ma = a
			val MetaBase mb = b
			val sna = ma.simpleName
			val snb = mb.simpleName
			var result = sna.compareTo(snb)
			if (result === 0) {
				result = a.fullName.compareTo(b.fullName)
			}
			result
		])
		ownset.addAll(checkArray(theProperties, "theOwnProperties"))
		val Type me = this
		for (prop : ownset) {
			val name = prop.simpleName
			for (parent : inheritedParents) {
				for (parentProp : parent.properties) {
					if (parentProp.simpleName.equals(name)) {
						throw new IllegalStateException(theType
							+" has a property "+name
							+" which clashed with a property of "+parent
							+" (if they are the 'same' property, refactor to represent that)"
						)
					}
				}
			}
			prop.parent = me
		}
		val virtualProps = new ArrayList<Property<JAVA_TYPE,?>>
		val iter = ownset.iterator
		while (iter.hasNext) {
			val prop = iter.next
			if (prop.virtual) {
				iter.remove
				virtualProps.add(prop)
			}
		}
		properties = ownset
		objectProperties = ownset.filter(ObjectProperty)
		primitiveProperties = ownset.filter(PrimitiveProperty)
		virtualProperties = virtualProps
		virtualPropertyCount = virtualProperties.length
		if (properties.length != (objectProperties.length + primitiveProperties.length)) {
			throw new IllegalStateException(theType
				+": all properties must be either ObjectProperty or PrimitiveProperty")
		}
		// TODO We should verify that Properties can only depend on "accepted types"
		// (From modules we depend on)

		// Merge all properties in allProperties
		for (p : parents) {
			ownset.addAll(p.inheritedProperties as Property<JAVA_TYPE,?>[])
			virtualProps.addAll(p.inheritedVirtualProperties as Property<JAVA_TYPE,?>[])
		}
		inheritedProperties = ownset
		inheritedVirtualProperties = virtualProps
		inheritedPropertyCount = inheritedProperties.length
		inheritedObjectProperties = ownset.filter(ObjectProperty)
		inheritedPrimitiveProperties = ownset.filter(PrimitiveProperty)
		typeId = registration.typeId

	    var _primitivePropertyBitsTotal = 0
	    var _primitivePropertyByteTotal = 0
	    var _sixtyFourBitPropertyCount = 0
	    var _nonSixtyFourBitPropertyCount = 0
	    var _nonLongPrimitivePropertyCount = 0
	    var _booleanPrimitivePropertyCount = 0
	    var _bytePrimitivePropertyCount = 0
	    var _charPrimitivePropertyCount = 0
	    var _shortPrimitivePropertyCount = 0
	    var _intPrimitivePropertyCount = 0
	    var _longPrimitivePropertyCount = 0
	    var _floatPrimitivePropertyCount = 0
	    var _doublePrimitivePropertyCount = 0

	    val Map<String,Property<?,?>> _simpleNameToProperty = newHashMap()
		for (prop : properties as Property<?,?>[]) {
			if (prop instanceof PrimitiveProperty<?,?,?>) {
				_primitivePropertyBitsTotal = _primitivePropertyBitsTotal + prop.bits
				_primitivePropertyByteTotal = _primitivePropertyByteTotal + prop.bytes
				if (prop.sixtyFourBit) {
					_sixtyFourBitPropertyCount = _sixtyFourBitPropertyCount + 1
				} else {
					_nonSixtyFourBitPropertyCount = _nonSixtyFourBitPropertyCount + 1
				}
				if (prop instanceof LongProperty<?,?,?>) {
					_longPrimitivePropertyCount = _longPrimitivePropertyCount + 1
				} else {
					_nonLongPrimitivePropertyCount = _nonLongPrimitivePropertyCount + 1
					if (prop instanceof BooleanProperty<?,?,?>) {
						_booleanPrimitivePropertyCount = _booleanPrimitivePropertyCount + 1
					} else if (prop instanceof ByteProperty<?,?,?>) {
						_bytePrimitivePropertyCount = _bytePrimitivePropertyCount + 1
					} else if (prop instanceof CharacterProperty<?,?,?>) {
						_charPrimitivePropertyCount = _charPrimitivePropertyCount + 1
					} else if (prop instanceof ShortProperty<?,?,?>) {
						_shortPrimitivePropertyCount = _shortPrimitivePropertyCount + 1
					} else if (prop instanceof IntegerProperty<?,?,?>) {
						_intPrimitivePropertyCount = _intPrimitivePropertyCount + 1
					} else if (prop instanceof FloatProperty<?,?,?>) {
						_floatPrimitivePropertyCount = _floatPrimitivePropertyCount + 1
					} else if (prop instanceof DoubleProperty<?,?,?>) {
						_doublePrimitivePropertyCount = _doublePrimitivePropertyCount + 1
					}
				}
			}
		}
		for (prop : inheritedProperties) {
			// Property name clash is not allowed between parent either
			val other = _simpleNameToProperty.put(prop.simpleName, prop)
			if ((other !== null) && (other !== prop)) {
				val msg = theType
					+" inherits multiple properties with simpleName "+prop.simpleName
					+" (at least "+prop.fullName+" and "+other.fullName+")"
				throw new IllegalStateException(msg)
			}
		}
		for (prop : inheritedVirtualProperties) {
			// Property name clash is not allowed between parent either
			val other = _simpleNameToProperty.put(prop.simpleName, prop)
			if ((other !== null) && (other !== prop)) {
				val msg = theType
					+" inherits multiple properties with simpleName "+prop.simpleName
					+" (at least "+prop.fullName+" and "+other.fullName+")"
				throw new IllegalStateException(msg)
			}
		}
	    propertyCount = properties.length
	    primitivePropertyCount = primitiveProperties.length
	    objectPropertyCount = objectProperties.length
	    primitivePropertyBitsTotal = _primitivePropertyBitsTotal
	    primitivePropertyByteTotal = _primitivePropertyByteTotal
	    sixtyFourBitPropertyCount = _sixtyFourBitPropertyCount
	    nonSixtyFourBitPropertyCount = _nonSixtyFourBitPropertyCount
	    nonLongPrimitivePropertyCount = _nonLongPrimitivePropertyCount
	    booleanPrimitivePropertyCount = _booleanPrimitivePropertyCount
	    bytePrimitivePropertyCount = _bytePrimitivePropertyCount
	    charPrimitivePropertyCount = _charPrimitivePropertyCount
	    shortPrimitivePropertyCount = _shortPrimitivePropertyCount
	    intPrimitivePropertyCount = _intPrimitivePropertyCount
	    longPrimitivePropertyCount = _longPrimitivePropertyCount
	    floatPrimitivePropertyCount = _floatPrimitivePropertyCount
	    doublePrimitivePropertyCount = _doublePrimitivePropertyCount
	    simpleNameToProperty = Collections::unmodifiableMap(_simpleNameToProperty)

		footprint = Footprint.round(_primitivePropertyByteTotal + Footprint.REFERENCE * objectPropertyCount)
	    var total = footprint
		for (p : parents) {
			total = total + p.footprint
		}
		inheritedFootprint = total + Footprint.OBJECT_SIZE
	}

	/** Returns the VALUE component type, if available, or null */
	def final Type<?> getValueComponentType(JAVA_TYPE instance) {
		if (componentTypes.length > VALUE_COMPONENT) {
			componentTypes.get(VALUE_COMPONENT).getObject(instance)
		} else
			null
	}

	/** Returns the KEY component type, if available, or null */
	def final Type<?> getKeyComponentType(JAVA_TYPE instance) {
		if (componentTypes.length > KEY_COMPONENT)
			componentTypes.get(KEY_COMPONENT).getObject(instance)
		else
			null
	}

	/** Returns the THIRD component type, if available, or null */
	def final Type<?> getThirdComponentType(JAVA_TYPE instance) {
		if (componentTypes.length > THIRD_COMPONENT)
			componentTypes.get(THIRD_COMPONENT).getObject(instance)
		else
			null
	}

    /** Returns a new E array of given size. */
    def final JAVA_TYPE[] newArray(int length) {
    	if (length == 0) {
    		return empty
    	}
        java.lang.reflect.Array.newInstance(type, length) as JAVA_TYPE[]
    }

	/** The package */
	def final TypePackage pkg() {
		if (parent == null) {
			throw new IllegalStateException("pkg of "+this+" is null")
		}
		parent
	}

	/**
	 * Returns true if both Type instances represent the same Java class.
	 * This is possible if they belong to different type hierarchies.
	 */
	def final sameType(Type<?> other) {
		(other != null) && (other.type == type)
	}

	/**
	 * Returns true if the given Type is one of this Type's parents.
	 */
	def final isChildOf(Type<?> maybeParent) {
		(maybeParent != null) && inheritedParents.contains(maybeParent)
	}

	/**
	 * Returns true if the given Type is one of this Type's children.
	 */
	def final isParentOf(Type<?> maybeChild) {
		(maybeChild != null) && maybeChild.isChildOf(this)
	}

	/** Delegates to "constructor" to allow the creation of instances of the type. */
	def final JAVA_TYPE create() {
		constructor.get()
	}
}


/**
 * The Property visitor
 */
interface PropertyVisitor {
	/** Visits a Boolean Property */
	def void visit(BooleanProperty<?,?,?> prop)

	/** Visits a Byte Property */
	def void visit(ByteProperty<?,?,?> prop)

	/** Visits a Character Property */
	def void visit(CharacterProperty<?,?,?> prop)

	/** Visits a Short Property */
	def void visit(ShortProperty<?,?,?> prop)

	/** Visits a Integer Property */
	def void visit(IntegerProperty<?,?,?> prop)

	/** Visits a Long Property */
	def void visit(LongProperty<?,?,?> prop)

	/** Visits a Float Property */
	def void visit(FloatProperty<?,?,?> prop)

	/** Visits a Double Property */
	def void visit(DoubleProperty<?,?,?> prop)

	/** Visits a Object Property */
	def void visit(ObjectProperty<?,?> prop)
}

/**
 * Represents a Property of a Type.
 *
 * Beyond defining the type, name and different IDs of a Property, it's main
 * use is to give a *fast generic access* to the value of the property,
 * allowing frameworks to manipulate the data of instances of Types, without
 * actually knowing the Java Class of the Type at compile time, and, most
 * importantly, *without using Reflection*. This means this API should allow
 * generic type and property manipulation even in GWT.
 *
 * This, of course, doesn't come for free. To allow fast generic access to the
 * value of the Property, the Property instance must be a sub-class of Property,
 * and therefore one additional Class object is produced for every Property of
 * a domain object. Each such Class instance requires a few hundred bytes, but
 * the cost is once-per-property, and so independent of the number of
 * *instances*.
 *
 * @author monster
 */
abstract class Property<OWNER_TYPE, PROPERTY_TYPE>
extends MetaBase<Type<OWNER_TYPE>> {
	/** When a Type has no properties */
	public static val Property[] NO_PROPERTIES = <Property>newArrayOfSize(0)

	/** Only for internal validation ... */
	package val Class<OWNER_TYPE> ownerClass
	/** The content/data Type of this property */
	public val Class<PROPERTY_TYPE> contentTypeClass
	/** The content/data Type of this property */
	var Type<PROPERTY_TYPE> contentType
	/** Maps a type ID to an "inherited Property ID" */
	val inheritedIndex = new AtomicReference<byte[]>()
	/** The zero-based global property ID */
	public val int globalPropertyId
	/** The zero-based property ID, within the owner type */
	public val int propertyId
	/** Does this represent a primitive property */
	public val boolean primitive
	/** The basic type of a Property. */
	public val PropertyType type
	/** Does this represent a "meta" property? */
	public val boolean meta
	/**
	 * The zero-based Long-or-Object property ID, within the owner type.
	 *
	 * It's purpose is that Long cannot be represented as a double,
	 * and therefore Java Long are *objects* anyway in GWT. So we want
	 * to split between any primitive value that can be represented
	 * as a double, and the rest, which are Long and Objects.
	 */
	public val int longOrObjectPropertyId
	/** Does this represent a "virtual" property? */
	public val boolean virtual
	/** The virtual property ID */
	public val int virtualPropertyId

	/** Constructor */
	package new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, ? extends Converter<PROPERTY_TYPE>> theData) {
		super(requireNonNull(requireNonNull(theData, "theData").owner, "theData.owner").name+'.'
			+requireNonNull(theData.simpleName, "theData.simpleName"),
			theData.simpleName, theData.globalId)
		requireNonNull(theData.converter, "theData.converter)")
		requireNonNull(theData.converter.type, "theData.converter.type)")
		contentTypeClass = requireNonNull(theData.dataType, "theData.dataType")
		ownerClass = theData.owner
		primitive = !(this instanceof ObjectProperty) && Type.primTypes.contains(contentTypeClass)
		globalPropertyId = theData.globalPropertyId
		propertyId = theData.propertyId
		longOrObjectPropertyId = theData.longOrObjectPropertyId
		type = theData.type
		meta = MetaBase.isAssignableFrom(theData.owner)
		// Only not-null at this point for meta-properties
		// (which never get registered as part of the Type instantiation)
		parent = theData.ownerType.get(0)
		virtual = theData.virtual
		virtualPropertyId = theData.virtualPropertyId
	}

	/**
	 * Returns true if both Property instances represent the same property
	 * in the same Java class. This is possible if they belong to different
	 * type hierarchies.
	 */
	def final boolean sameProperty(Property<?,?> other) {
		(other != null) && (other.fullName.equals(fullName))
	}

	/** The owner type */
	def final Type<OWNER_TYPE> owner() {
		if (parent == null) {
			throw new IllegalStateException("owner of "+this+" is null")
		}
		parent
	}

	/** The content/data Type of this property */
	def final Type<PROPERTY_TYPE> contentType() {
		if (contentType === null) {
			contentType = hierarchy().findType(contentTypeClass)
			requireNonNull(contentType, contentTypeClass.name)
		}
		contentType
	}

	/**
	 * The zero-based property ID, within the inheritedProperties array of the
	 * given type. -1 when not found.
	 */
	def final int inheritedPropertyId(Type<?> type) {
		// TODO This can probably be improved ...
		val typeID = requireNonNull(type, "type").typeId
		val oldArray = inheritedIndex.get
		var array = oldArray
		if (array === null) {
			array = newByteArrayOfSize(0)
		}
		if (array.length <= typeID) {
			val newArray = newByteArrayOfSize(typeID*2)
			System.arraycopy(array, 0, newArray, 0, array.length)
			array = newArray
		}
		var result = array.get(typeID)
		if (result === 0) {
			result = (-2) as byte
			var index = 0
			for (p : type.inheritedProperties) {
				if (p === this) {
					result = index as byte
				}
				index = index + 1
			}
			array.set(typeID, (result + 1) as byte)
			if (!inheritedIndex.compareAndSet(oldArray, array)) {
				return inheritedPropertyId(type)
			}
		} else if (result !== -1) {
			result = (result - 1) as byte
		}
		result
	}

	/** Returns the value of this property, as an Object */
	def PROPERTY_TYPE getObject(OWNER_TYPE object)

	/** Sets the value of this property, as an Object */
	def OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value)

	/** Accepts the visitor */
	def void accept(PropertyVisitor visitor)

	/** Copy the value of the Property from the source to the target */
	def void copyValue(OWNER_TYPE source, OWNER_TYPE target)

	/** Returns true, if the property is immutable. */
	def boolean isImmutable()
}

/** Temporary Helper Object, used for Object Property creation. */
package final class DummyConverter<E> implements Converter<E> {

	val Class<E> type

	package new(Class<E> theType) {
		type = theType
	}

    /**
     * The type of Object being converted.
     *
     * @return the class (type) of the Object that is converted by this Converter interface.
     */
    override Class<E> type() {
    	type
    }

    /**
     * Returns the number of bits required to store the object data.
     *
     * Use the primitive type size, if unsure/variable.
     * Use 0 or -1 if not a primitive type converter.
     */
    override int bits() { 0 }

}

/**
 * Represents an Object (non-primitive) Property.
 * This is also the base-class of the meta-properties.
 *
 * @author monster
 */
class ObjectProperty<OWNER_TYPE, PROPERTY_TYPE>
extends Property<OWNER_TYPE, PROPERTY_TYPE> {
	/** The zero-based Object (non-primitive) property ID, within the owner type */
	public val int objectPropertyId

	/** Do we "own" (shared==false) this object? */
	public val boolean shared

    /** Is the actual instance preserved, when setting this property in the owner type? */
    public val boolean actualInstance

    /** Is only the exact declared type accepted? (No subclass?) */
    public val boolean exactType

    /** The Getter Functor */
    public val ObjectFuncObject<PROPERTY_TYPE,OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectObject<OWNER_TYPE,OWNER_TYPE,PROPERTY_TYPE> setter

	/** Is this object a "Bean"? */
	public val boolean bean

	/** Constructor */
	package new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, ? extends Converter<PROPERTY_TYPE>> theData,
		boolean theShared, boolean theActualInstance, boolean theExactType,
		ObjectFuncObject<PROPERTY_TYPE,OWNER_TYPE> theGetter,
		ObjectFuncObjectObject<OWNER_TYPE,OWNER_TYPE,PROPERTY_TYPE> theSetter) {
		super(theData)
		objectPropertyId = theData.specificTypePropId
		shared = theShared
		actualInstance = theActualInstance
		exactType = theExactType
		getter = theGetter
		setter = theSetter
		bean = Bean.isAssignableFrom(theData.dataType)
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		Class<PROPERTY_TYPE> theContentType, boolean theShared, boolean theActualInstance,
		boolean theExactType, ObjectFuncObject<PROPERTY_TYPE,OWNER_TYPE> theGetter,
		ObjectFuncObjectObject<OWNER_TYPE,OWNER_TYPE,PROPERTY_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, new DummyConverter(theContentType),
			PropertyType::OBJECT, -1, theContentType, theVirtual), theShared, theActualInstance,
			theExactType, requireNonNull(theGetter, "theGetter"),
			theSetter)
	}

	override final getObject(OWNER_TYPE object) {
		getter.apply(object)
	}

	override final setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setter.apply(object, value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setObject(target, getObject(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}

/**
 * Getter for Meta-Properties
 *
 * Returns the value of this meta-property, as an Object.
 * If the value is null, and a default value was provided,
 * then the default value is returned.
 */
package class MetaGetter<OWNER_TYPE extends MetaBase<?>,PROPERTY_TYPE>
implements ObjectFuncObject<PROPERTY_TYPE,OWNER_TYPE> {
	/** The zero-based global property ID */
	public val int globalPropertyId

    /** The default value */
    public val PROPERTY_TYPE defaultValue

    /** Constructor */
    new (int theGlobalPropertyId, PROPERTY_TYPE theDefaultValue) {
    	globalPropertyId = theGlobalPropertyId
    	defaultValue = theDefaultValue
    }

	override final apply(OWNER_TYPE object) {
		val array = object.metaProperties
		val index = globalPropertyId
		val result = if (index >= array.length) null else array.get(index)
		if (result == null) defaultValue else result as PROPERTY_TYPE
	}
}

/** Setter for Meta-Properties */
package class MetaSetter<OWNER_TYPE extends MetaBase<?>,PROPERTY_TYPE>
implements ObjectFuncObjectObject<OWNER_TYPE,OWNER_TYPE,PROPERTY_TYPE> {
	/** The zero-based global property ID */
	public val int globalPropertyId

    /** Constructor */
    new (int theGlobalPropertyId) {
    	globalPropertyId = theGlobalPropertyId
    }

	override final apply(OWNER_TYPE object, PROPERTY_TYPE value) {
		Hierarchy.setObject(object, globalPropertyId, value)
		object
	}
}

/**
 * Represents an Meta-Property; a property that applies to one of the MetaBase
 * subclasses. Our assumption is that there will be few of them, and few
 * instances of MetaBase itself. So for keeping things simple and fast, we only
 * use Objects, so primitive values are stored as wrappers
 *
 * The Meta-Property instance should be created like this:
 *     public final static MyMetaProperty MP = Hierarchy.postCreateMetaProperty(new MyMetaProperty(...));
 * To make sure it is correctly registered.
 *
 * To simplify the user code, in the case of meta-properties that would ideally
 * be primitive properties, we provide a "default value", to eliminate the
 * possibility of getting "null" as value.
 *
 * @author monster
 */
class MetaProperty<OWNER_TYPE extends MetaBase<?>, PROPERTY_TYPE>
extends ObjectProperty<OWNER_TYPE, PROPERTY_TYPE> {

    /** The default value */
    public val PROPERTY_TYPE defaultValue

	/** Check the owner type, and make sure all "system" instances are already properly initialized */
	private static def checkOwnerType(Type<?> theOwner) {
		if (!MetaBase.isAssignableFrom(requireNonNull(theOwner, "theOwner").type)) {
			throw new IllegalArgumentException(theOwner+" is not a meta-type")
		}
		theOwner
	}

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, ? extends Converter<PROPERTY_TYPE>> theData,
		PROPERTY_TYPE theDefaultValue) {
		super(theData, true, true, false,
			new MetaGetter<OWNER_TYPE,PROPERTY_TYPE>(theData.globalPropertyId, theDefaultValue),
			new MetaSetter<OWNER_TYPE,PROPERTY_TYPE>(theData.globalPropertyId))
		if (theDefaultValue != null) {
			if (!theData.dataType.isInstance(theDefaultValue)) {
				throw new IllegalArgumentException()
			}
		}
		defaultValue = theDefaultValue
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Type<OWNER_TYPE> theOwner, String theSimpleName,
		Class<PROPERTY_TYPE> theContentType, boolean theVirtual) {
		this(builder, theOwner, theSimpleName, theContentType, null, theVirtual)
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Type<OWNER_TYPE> theOwner, String theSimpleName,
		Class<PROPERTY_TYPE> theContentType, PROPERTY_TYPE theDefaultValue, boolean theVirtual) {
		this(builder.preRegisterProperty(checkOwnerType(theOwner).type as Class<OWNER_TYPE>,
			theSimpleName, new DummyConverter(theContentType),
			PropertyType::OBJECT, -1, theContentType, theVirtual), theDefaultValue)
		parent = theOwner
	}
}


/**
 * Represents an Primitive (non-Object) Property.
 *
 * The purpose of the Converter, is that we need to be able to represent every
 * property as an Object anyway. So with the Converter, we enable that Object
 * to be something else then just a "primitive wrapper". We could, for whatever
 * reason, for example, store a value internally as a long, and externally as
 * a "Handle" (non-primitive), using a Converter.
 *
 * @author monster
 */
abstract class PrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<PROPERTY_TYPE>>
extends Property<OWNER_TYPE, PROPERTY_TYPE> {
	/** The default converters */
	/** The zero-based Primitive (non-Object) property ID, within the owner type */
	public val int primitivePropertyId
	/** The number of bits required to store this value (boolean == 1) */
	public val int bits
	/** The number of bytes required to store this value (bits rounded up to a multiple of 8; boolean == 1) */
	public val int bytes
	/** Is this a floating-point property? */
	public val boolean floatingPoint
	/** Is this a 64-bit property? */
	public val boolean sixtyFourBit
	/** The zero-based non-64-bit property ID, within the owner type */
	public val int nonSixtyFourBitPropertyId
	/** The zero-based 64-bit property ID, within the owner type */
	public val int sixtyFourBitPropertyId
	/**
	 * Long is the only primitive Java type that *cannot be accurately
	 * represented in JavaScript*, and so is treated as a special case
	 * to serve the GWT-compatible version.
	 *
	 * The long property Id exists only in Long properties, of course.
	 */
	public val int nonLongPropertyId
	/** The converter. Used to convert primitive values to/from Objects. */
	public val CONVERTER converter
	/** Is this a signed property? */
	public val boolean signed
	/** Is this a default primitive "wrapper" property? */
	public val boolean wrapper

	/** Constructor */
	package new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData) {
		super(theData)
		converter = theData.converter
		primitivePropertyId = theData.primitivePropertyId
		bits = theData.bits
		sixtyFourBit = (64 == bits)
		bytes = if (bits % 8 == 0) bits/8 else 1+bits/8
		floatingPoint = (theData.type == PropertyType::FLOAT) || (theData.type == PropertyType::DOUBLE)
		nonSixtyFourBitPropertyId = theData.nonSixtyFourBitPropertyId
		sixtyFourBitPropertyId = theData.sixtyFourBitPropertyId
		nonLongPropertyId = theData.nonLongPropertyId
		signed = (theData.type != PropertyType::BOOLEAN) && (theData.type != PropertyType::CHARACTER)
		val tp = theData.dataType
		wrapper = (tp == Boolean) || (tp == Byte)
			|| (tp == Short) || (tp == Character)
			|| (tp == Integer) || (tp == Long)
			|| (tp == Float) || (tp == Double)
	}
}


/**
 * Represents a non-64-bit (not Long/Double) primitive Property.
 *
 * @author monster
 */
abstract class NonSixtyFourBitPrimitiveProperty
<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<PROPERTY_TYPE>>
extends PrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** Constructor */
	package new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData) {
		super(theData)
	}
}


/**
 * Represents a 64-bit primitive Long/Double Property.
 *
 * @author monster
 */
abstract class SixtyFourBitPrimitiveProperty
<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<PROPERTY_TYPE>>
extends PrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** Constructor */
	package new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData) {
		super(theData)
	}
}


/**
 * Represents an primitive boolean Property.
 *
 * @author monster
 */
class BooleanProperty
<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends BooleanConverter<OWNER_TYPE, PROPERTY_TYPE>>
extends NonSixtyFourBitPrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** The zero-based Boolean property ID, within the owner type */
	public val int booleanPropertyId

    /** The Getter Functor */
    public val BooleanFuncObject<OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> setter

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData,
		BooleanFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> theSetter) {
		super(theData)
		booleanPropertyId = theData.specificTypePropId
		getter = theGetter
		setter = theSetter
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner,
		String theSimpleName, CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		BooleanFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, theConverter,
			PropertyType::BOOLEAN, 1, dataType, theVirtual), requireNonNull(theGetter, "theGetter"),
			theSetter)
	}

	/** Returns the value of this property, as an Object */
	override final PROPERTY_TYPE getObject(OWNER_TYPE object) {
		converter.toObject(object, getBoolean(object))
	}

	/** Sets the value of this property, as an Object */
	override final OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setBoolean(object, converter.fromObject(object, value))
	}

	/** Returns the value of this property, as a boolean */
	def final boolean getBoolean(OWNER_TYPE object) {
		getter.apply(object)
	}

	/** Sets the value of this property, as a boolean */
	def final OWNER_TYPE setBoolean(OWNER_TYPE object, boolean value) {
		setter.apply(object,value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setBoolean(target, getBoolean(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}


/**
 * Represents an true boolean Property.
 *
 * @author monster
 */
class TrueBooleanProperty<OWNER_TYPE>
extends BooleanProperty<OWNER_TYPE, Boolean, BooleanConverter<OWNER_TYPE, Boolean>> {
	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		BooleanFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		super(builder, theOwner, theSimpleName,
			BooleanConverter.DEFAULT as BooleanConverter<OWNER_TYPE, Boolean>, Boolean,
			theGetter, theSetter, theVirtual
		)
	}
}


/**
 * Represents an primitive byte Property.
 *
 * @author monster
 */
class ByteProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends ByteConverter<OWNER_TYPE, PROPERTY_TYPE>>
extends NonSixtyFourBitPrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** The zero-based Byte property ID, within the owner type */
	public val int bytePropertyId

    /** The Getter Functor */
    public val ByteFuncObject<OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> setter

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData,
		ByteFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> theSetter) {
		super(theData)
		bytePropertyId = theData.specificTypePropId
		getter = theGetter
		setter = theSetter
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		ByteFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, theConverter,
			PropertyType::BYTE, theBits, dataType, theVirtual
		), requireNonNull(theGetter, "theGetter"), theSetter)
	}

	/** Returns the value of this property, as an Object */
	override final PROPERTY_TYPE getObject(OWNER_TYPE object) {
		converter.toObject(object, getByte(object))
	}

	/** Sets the value of this property, as an Object */
	override final OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setByte(object, converter.fromObject(object, value))
	}

	/** Returns the value of this property, as a byte */
	def final byte getByte(OWNER_TYPE object) {
		getter.apply(object)
	}

	/** Sets the value of this property, as a byte */
	def final OWNER_TYPE setByte(OWNER_TYPE object, byte value) {
		setter.apply(object,value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setByte(target, getByte(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}


/**
 * Represents an true byte Property.
 *
 * @author monster
 */
class TrueByteProperty<OWNER_TYPE>
extends ByteProperty<OWNER_TYPE, Byte, ByteConverter<OWNER_TYPE, Byte>> {
	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		ByteFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		super(builder, theOwner, theSimpleName,
			ByteConverter.DEFAULT as ByteConverter<OWNER_TYPE, Byte>, 8,
			Byte, theGetter, theSetter, theVirtual
		)
	}
}


/**
 * Represents a primitive char Property.
 *
 * @author monster
 */
class CharacterProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends CharConverter<OWNER_TYPE, PROPERTY_TYPE>>
extends NonSixtyFourBitPrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** The zero-based Character property ID, within the owner type */
	public val int characterPropertyId

    /** The Getter Functor */
    public val CharFuncObject<OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> setter

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData,
		CharFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> theSetter) {
		super(theData)
		characterPropertyId = theData.specificTypePropId
		getter = theGetter
		setter = theSetter
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		CharFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, theConverter,
			PropertyType::CHARACTER, theBits, dataType, theVirtual
		), requireNonNull(theGetter, "theGetter"), theSetter)
	}

	/** Returns the value of this property, as an Object */
	override final PROPERTY_TYPE getObject(OWNER_TYPE object) {
		converter.toObject(object, getChar(object))
	}

	/** Sets the value of this property, as an Object */
	override final OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setChar(object, converter.fromObject(object, value))
	}

	/** Returns the value of this property, as a char */
	def final char getChar(OWNER_TYPE object) {
		getter.apply(object)
	}

	/** Sets the value of this property, as a char */
	def final OWNER_TYPE setChar(OWNER_TYPE object, char value) {
		setter.apply(object,value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setChar(target, getChar(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}


/**
 * Represents a true char Property.
 *
 * @author monster
 */
class TrueCharacterProperty<OWNER_TYPE>
extends CharacterProperty<OWNER_TYPE, Character, CharConverter<OWNER_TYPE, Character>> {
	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner,
		String theSimpleName, CharFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		super(builder, theOwner, theSimpleName,
			CharConverter.DEFAULT as CharConverter<OWNER_TYPE, Character>,
			16, Character, theGetter, theSetter, theVirtual
		)
	}
}


/**
 * Represents a primitive short Property.
 *
 * @author monster
 */
class ShortProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER
extends ShortConverter<OWNER_TYPE, PROPERTY_TYPE>>
extends NonSixtyFourBitPrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** The zero-based Short property ID, within the owner type */
	public val int shortPropertyId

    /** The Getter Functor */
    public val ShortFuncObject<OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> setter

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData,
		ShortFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> theSetter) {
		super(theData)
		shortPropertyId = theData.specificTypePropId
		getter = theGetter
		setter = theSetter
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		ShortFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, theConverter,
			PropertyType::SHORT, theBits, dataType, theVirtual
		), requireNonNull(theGetter, "theGetter"), theSetter)
	}

	/** Returns the value of this property, as an Object */
	override final PROPERTY_TYPE getObject(OWNER_TYPE object) {
		converter.toObject(object, getShort(object))
	}

	/** Sets the value of this property, as an Object */
	override final OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setShort(object, converter.fromObject(object, value))
	}

	/** Returns the value of this property, as a short */
	def final short getShort(OWNER_TYPE object) {
		getter.apply(object)
	}

	/** Sets the value of this property, as a short */
	def final OWNER_TYPE setShort(OWNER_TYPE object, short value) {
		setter.apply(object,value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setShort(target, getShort(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}


/**
 * Represents a true short Property.
 *
 * @author monster
 */
 class TrueShortProperty<OWNER_TYPE>
extends ShortProperty<OWNER_TYPE, Short, ShortConverter<OWNER_TYPE, Short>> {
	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		ShortFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		super(builder, theOwner, theSimpleName,
			ShortConverter.DEFAULT as ShortConverter<OWNER_TYPE, Short>,
			16, Short, theGetter, theSetter, theVirtual
		)
	}
}


/**
 * Represents an primitive integer Property.
 *
 * @author monster
 */
class IntegerProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends IntConverter<OWNER_TYPE, PROPERTY_TYPE>>
extends NonSixtyFourBitPrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** The zero-based Integer property ID, within the owner type */
	public val int integerPropertyId

    /** The Getter Functor */
    public val IntFuncObject<OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> setter

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData,
		IntFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> theSetter) {
		super(theData)
		integerPropertyId = theData.specificTypePropId
		getter = theGetter
		setter = theSetter
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		IntFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, theConverter,
			PropertyType::INTEGER, theBits, dataType, theVirtual
		), requireNonNull(theGetter, "theGetter"), theSetter)
	}

	/** Returns the value of this property, as an Object */
	override final PROPERTY_TYPE getObject(OWNER_TYPE object) {
		converter.toObject(object, getInt(object))
	}

	/** Sets the value of this property, as an Object */
	override final OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setInt(object, converter.fromObject(object, value))
	}

	/** Returns the value of this property, as an int */
	def final int getInt(OWNER_TYPE object) {
		getter.apply(object)
	}

	/** Sets the value of this property, as an int */
	def final OWNER_TYPE setInt(OWNER_TYPE object, int value) {
		setter.apply(object,value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setInt(target, getInt(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}


/**
 * Represents a true primitive integer Property.
 *
 * @author monster
 */
class TrueIntegerProperty<OWNER_TYPE>
extends IntegerProperty<OWNER_TYPE, Integer, IntConverter<OWNER_TYPE, Integer>> {
	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner,
		String theSimpleName, IntFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		super(builder, theOwner, theSimpleName,
			IntConverter.DEFAULT as IntConverter<OWNER_TYPE, Integer>, 32,
			Integer, theGetter, theSetter, theVirtual
		)
	}
}


/**
 * Represents a primitive float Property.
 *
 * @author monster
 */
class FloatProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends FloatConverter<OWNER_TYPE, PROPERTY_TYPE>>
extends NonSixtyFourBitPrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** The zero-based Float property ID, within the owner type */
	public val int floatPropertyId

    /** The Getter Functor */
    public val FloatFuncObject<OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> setter

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData,
		FloatFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> theSetter) {
		super(theData)
		floatPropertyId = theData.specificTypePropId
		getter = theGetter
		setter = theSetter
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		FloatFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, theConverter,
			PropertyType::FLOAT, 32, dataType, theVirtual
		), requireNonNull(theGetter, "theGetter"), theSetter)
	}

	/** Returns the value of this property, as an Object */
	override PROPERTY_TYPE getObject(OWNER_TYPE object) {
		converter.toObject(object, getFloat(object))
	}

	/** Sets the value of this property, as an Object */
	override OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setFloat(object, converter.fromObject(object, value))
	}

	/** Returns the value of this property, as a float */
	def float getFloat(OWNER_TYPE object) {
		getter.apply(object)
	}

	/** Sets the value of this property, as a float */
	def OWNER_TYPE setFloat(OWNER_TYPE object, float value) {
		setter.apply(object,value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setFloat(target, getFloat(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}


/**
 * Represents a true primitive float Property.
 *
 * @author monster
 */
class TrueFloatProperty<OWNER_TYPE>
extends FloatProperty<OWNER_TYPE, Float, FloatConverter<OWNER_TYPE, Float>> {
	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		FloatFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		super(builder, theOwner, theSimpleName,
			FloatConverter.DEFAULT as FloatConverter<OWNER_TYPE, Float>,
			Float, theGetter, theSetter, theVirtual
		)
	}
}


/**
 * Represents a primitive long Property.
 *
 * @author monster
 */
class LongProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends LongConverter<OWNER_TYPE, PROPERTY_TYPE>>
extends SixtyFourBitPrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** The zero-based Long property ID, within the owner type */
	public val int longPropertyId

    /** The Getter Functor */
    public val LongFuncObject<OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> setter

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData,
		LongFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> theSetter) {
		super(theData)
		longPropertyId = theData.specificTypePropId
		getter = theGetter
		setter = theSetter
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, int theBits, Class<PROPERTY_TYPE> dataType,
		LongFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, theConverter,
			PropertyType::LONG, theBits, dataType, theVirtual
		), requireNonNull(theGetter, "theGetter"), theSetter)
	}

	/** Returns the value of this property, as an Object */
	override final PROPERTY_TYPE getObject(OWNER_TYPE object) {
		converter.toObject(object, getLong(object))
	}

	/** Sets the value of this property, as an Object */
	override final OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setLong(object, converter.fromObject(object, value))
	}

	/** Returns the value of this property, as a long */
	def final long getLong(OWNER_TYPE object) {
		getter.apply(object)
	}

	/** Sets the value of this property, as a long */
	def final OWNER_TYPE setLong(OWNER_TYPE object, long value) {
		setter.apply(object,value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setLong(target, getLong(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}


/**
 * Represents a true primitive long Property.
 *
 * @author monster
 */
class TrueLongProperty<OWNER_TYPE>
extends LongProperty<OWNER_TYPE, Long, LongConverter<OWNER_TYPE, Long>> {
	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner, String theSimpleName,
		LongFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		super(builder, theOwner, theSimpleName,
			LongConverter.DEFAULT as LongConverter<OWNER_TYPE, Long>,
			64, Long, theGetter, theSetter, theVirtual
		)
	}
}


/**
 * Represents a primitive double Property.
 *
 * @author monster
 */
class DoubleProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER
extends DoubleConverter<OWNER_TYPE, PROPERTY_TYPE>>
extends SixtyFourBitPrimitiveProperty<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> {
	/** The zero-based Double property ID, within the owner type */
	public val int doublePropertyId

    /** The Getter Functor */
    public val DoubleFuncObject<OWNER_TYPE> getter

    /** The Setter Functor */
    public val ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> setter

	/** Constructor */
	private new(PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> theData,
		DoubleFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> theSetter) {
		super(theData)
		doublePropertyId = theData.specificTypePropId
		getter = theGetter
		setter = theSetter
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner,
		String theSimpleName, CONVERTER theConverter, Class<PROPERTY_TYPE> dataType,
		DoubleFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		this(builder.preRegisterProperty(theOwner, theSimpleName, theConverter,
			PropertyType::DOUBLE, 64, dataType, theVirtual
		), requireNonNull(theGetter, "theGetter"), theSetter)
	}

	/** Returns the value of this property, as an Object */
	override final PROPERTY_TYPE getObject(OWNER_TYPE object) {
		converter.toObject(object, getDouble(object))
	}

	/** Sets the value of this property, as an Object */
	override final OWNER_TYPE setObject(OWNER_TYPE object, PROPERTY_TYPE value) {
		setDouble(object, converter.fromObject(object, value))
	}

	/** Returns the value of this property, as a double */
	def final double getDouble(OWNER_TYPE object) {
		getter.apply(object)
	}

	/** Sets the value of this property, as a double */
	def final OWNER_TYPE setDouble(OWNER_TYPE object, double value) {
		setter.apply(object,value)
	}

	/** Accepts the visitor */
	override final void accept(PropertyVisitor visitor) {
		visitor.visit(this)
	}

	/** Copy the value of the Property from the source to the target */
	override final void copyValue(OWNER_TYPE source, OWNER_TYPE target) {
		setDouble(target, getDouble(source))
	}

	/** Returns true, if the property is immutable. */
	override final boolean isImmutable() {
		setter === null
	}
}


/**
 * Represents a true primitive double Property.
 *
 * @author monster
 */
class TrueDoubleProperty<OWNER_TYPE>
extends DoubleProperty<OWNER_TYPE, Double, DoubleConverter<OWNER_TYPE, Double>> {
	/** Constructor */
	protected new(HierarchyBuilder builder, Class<OWNER_TYPE> theOwner,
		String theSimpleName, DoubleFuncObject<OWNER_TYPE> theGetter,
		ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> theSetter, boolean theVirtual) {
		super(builder, theOwner, theSimpleName,
			DoubleConverter.DEFAULT as DoubleConverter<OWNER_TYPE, Double>,
			Double, theGetter, theSetter, theVirtual
		)
	}
}

/**
 * Special Hierarchy instance for the meta-types.
 *
 * @author monster
 */
public class MetaHierarchyBuilder extends HierarchyBuilder {
    private static val LOG = LoggerFactory.getLogger(MetaHierarchyBuilder)

	/** Makes sure all the constants are initialized. Can always be called safely. */
	static def init() {
		if (Meta.HIERARCHY.allTypes.length !== 4) {
			throw new IllegalStateException("META: "+Meta.HIERARCHY.allTypes.toList)
		}
	}

	/** Constructor */
	new() {
		super(MetaBase.name)
	}

	package override void checkNotClosed() {
		// NOP
	}

	/** Creates and returns the property creation parameters */
	override <OWNER_TYPE, PROPERTY_TYPE, CONVERTER extends Converter<PROPERTY_TYPE>>
	PropertyRegistration<OWNER_TYPE, PROPERTY_TYPE, CONVERTER> doPreRegisterProperty(
		Class<OWNER_TYPE> theOwner, String theSimpleName,
		CONVERTER theConverter, PropertyType thePropType,
		int theBits, boolean theMeta, Class<PROPERTY_TYPE> dataType, boolean theVirtual) {
		if (!theMeta) {
			throw new IllegalArgumentException(
				"MetaHierarchy supports only meta-properties: "+theSimpleName)
		}
		val result = super.doPreRegisterProperty(theOwner, theSimpleName, theConverter,
			thePropType, theBits, theMeta, dataType, theVirtual)
		// Meta properties are never actually registered as part of the (meta) type creation
		val Type metaType = Meta.HIERARCHY.findType(theOwner as Class)
		// metaType must be found, since theMeta is true
		result.ownerType.set(0, metaType)
		LOG.info("Registering meta-property "+theOwner.name+"."+theSimpleName
			+"("+dataType.name+")")
		result
	}

	/** Creates a Meta Property */
	def <OWNER_TYPE extends MetaBase<?>, PROPERTY_TYPE> MetaProperty<OWNER_TYPE, PROPERTY_TYPE>
		newMetaProperty(
		Type<OWNER_TYPE> theOwner, String theSimpleName,
		Class<PROPERTY_TYPE> theContentType, boolean theVirtual) {
		new MetaProperty(this, theOwner, theSimpleName, theContentType, null, theVirtual)
	}

	/** Creates a Meta Property */
	def <OWNER_TYPE extends MetaBase<?>, PROPERTY_TYPE> MetaProperty<OWNER_TYPE, PROPERTY_TYPE>
		newMetaProperty(
		Type<OWNER_TYPE> theOwner, String theSimpleName,
		Class<PROPERTY_TYPE> theContentType, PROPERTY_TYPE theDefaultValue, boolean theVirtual) {
		new MetaProperty(this, theOwner, theSimpleName, theContentType, theDefaultValue, theVirtual)
	}
}

/** Used for TypePackage instance configuration */
package class PackageRegistration {
	/** The hierarchy builder */
	public var HierarchyBuilder builder
	/** The global package id in the hierarchy */
	public var int packageId
	/** The global meta id in the hierarchy */
	public var int globalId
    /** All the types in this package */
    public var Type<?>[] types
	/** The actual package */
	public var Package pkg
	/** The simple name */
	public var String simpleName
	/** The name */
	public var String name
}


/**
 * Represents a Java package.
 *
 * WARNING: Due to Xtend problems with this class (probably related to the
 * use of java.lang.Package) keep this class *at the end of the file*.
 */
class TypePackage extends MetaBase<Hierarchy> {

    /** All the types in this package */
    public val Type<?>[] types

	/** The zero-based package ID */
	public val int packageId

	/** The actual package */
	public val Package pkg

	/** Constructor */
	private new(HierarchyBuilder builder, int theGlobalId, int thePackageId,
		String simpleName, String name, Package pkg, Type<?>[] theTypes) {
		super(name, simpleName, theGlobalId)
		packageId = thePackageId
		this.pkg = pkg
		types = theTypes
		for (t : theTypes) {
			t.parent = this
		}
	}

	/** Constructor */
	private new(PackageRegistration registration) {
		this(requireNonNull(registration, "registration").builder,
			registration.globalId, registration.packageId,
			registration.simpleName, registration.name,
			registration.pkg, registration.types
		)
	}

	/** Constructor */
	protected new(HierarchyBuilder builder, Type<?> ... theTypes) {
		this(builder.preRegisterPackage(theTypes))
	}
}

/** A Provider that always returns the same value */
public final class ConstantProvider<E> implements Provider<E> {

	/** The constant */
	val E constant

	/** Creates a new ConstantProvider */
	new (E theConstant) {
		constant = requireNonNull(theConstant, "theConstant")
	}

	/** Returns the constant */
	override get() {
		constant
	}
}

/** A Provider that returns Objects */
package final class ObjectProvider implements Provider<Object> {
	/** Returns the constant */
	override get() {
		new Object
	}

	/** The singleton instance */
	public static val INSTANCE = new ObjectProvider
}

/** A Provider that returns Lists */
package final class ListProvider implements Provider<List> {
	/** Returns the constant */
	override get() {
		new ArrayList
	}

	/** The singleton instance */
	public static val INSTANCE = new ListProvider
}

/** A Provider that returns Sets */
package final class SetProvider implements Provider<Set> {
	/** Returns the constant */
	override get() {
		new HashSet
	}

	/** The singleton instance */
	public static val INSTANCE = new SetProvider
}

/** A Provider that returns Maps */
package final class MapProvider implements Provider<Map> {
	/** Returns the constant */
	override get() {
		new HashMap
	}

	/** The singleton instance */
	public static val INSTANCE = new MapProvider
}

/** Implemented by Collections that want a different "content" the toArray */
public interface ContentOwner<E> {
	/** Returns the content */
	def E[] getContent();
}

/**
 * The "Meta" constant-holding interface for the java.* types.
 */
 @SuppressWarnings("rawtypes")
public interface JavaMeta {
	/** Used to represent single-parameter generic types, with unknown value type */
	val ObjectProperty[] ONE_NULL_OBJECT_PROP = newArrayOfSize(1)

	/** Used to represent dual-parameter generic types, with unknown value type */
	val ObjectProperty[] TWO_NULL_OBJECT_PROPS = newArrayOfSize(2)

	/** The Hierarchy of Java's Runtime Types */
	public static val BUILDER = HierarchyBuilderFactory.getHierarchyBuilder(Object.name)

	/** The primitive Serializable Type */
	public static val SERIALIZABLE = BUILDER.newType(Serializable, null, Kind.Trait)

	/** The primitive Object Type */
	public static val OBJECT = BUILDER.newType(Object, ObjectProvider.INSTANCE, Kind.Data)

	/** The primitive Void Type */
	public static val VOID = BUILDER.newType(Void, null, Kind.Data)

	/** The primitive Comparable Type */
	public static val COMPARABLE = BUILDER.newType(Comparable, null, Kind.Trait)

	/** The primitive Number Type */
	public static val NUMBER = BUILDER.newType(Number, null, Kind.Data, #[SERIALIZABLE])

	/** The primitive Boolean Type */
	public static val BOOLEAN = BUILDER.newType(Boolean, new ConstantProvider(Boolean.FALSE), Kind.Data, #[SERIALIZABLE, COMPARABLE])

	/** The primitive Byte Type */
	public static val BYTE = BUILDER.newType(Byte, new ConstantProvider(0 as byte), Kind.Data, #[NUMBER, COMPARABLE])

	/** The primitive Character Type */
	public static val CHARACTER = BUILDER.newType(Character, new ConstantProvider(0 as char), Kind.Data, #[SERIALIZABLE, COMPARABLE])

	/** The primitive Short Type */
	public static val SHORT = BUILDER.newType(Short, new ConstantProvider(0 as short), Kind.Data, #[NUMBER, COMPARABLE])

	/** The primitive Integer Type */
	public static val INTEGER = BUILDER.newType(Integer, new ConstantProvider(0), Kind.Data, #[NUMBER, COMPARABLE])

	/** The primitive Long Type */
	public static val LONG = BUILDER.newType(Long, new ConstantProvider(0L), Kind.Data, #[NUMBER, COMPARABLE])

	/** The primitive Float Type */
	public static val FLOAT = BUILDER.newType(Float, new ConstantProvider(0.0f), Kind.Data, #[NUMBER, COMPARABLE])

	/** The primitive Double Type */
	public static val DOUBLE = BUILDER.newType(Double, new ConstantProvider(0.0), Kind.Data, #[NUMBER, COMPARABLE])

	/** The primitive CharSequence Type */
	public static val CHAR_SEQUENCE = BUILDER.newType(CharSequence, null, Kind.Trait)

	/** The primitive String Type */
	public static val STRING = BUILDER.newType(String,
		new ConstantProvider(""), Kind.Data, #[SERIALIZABLE, CHAR_SEQUENCE, COMPARABLE])

	/** The Iterator Type */
	public static val ITERATOR = BUILDER.newType(Iterator, new ConstantProvider(Collections.emptyList.iterator),
		Kind.Trait, Type.NO_TYPE, Property.NO_PROPERTIES, ONE_NULL_OBJECT_PROP)

	/** The iterator virtual property of the Iterables */
    public static val ITERABLE_ITERATOR_PROP = BUILDER.newObjectProperty(
    	Iterable, "iterator", Iterator, false, false, false, [iterator], null, true)

	/** The Iterable Type */
	public static val ITERABLE = BUILDER.newType(Iterable, new ConstantProvider(Collections.emptyList),
		Kind.Trait, Type.NO_TYPE, <Property>newArrayList(ITERABLE_ITERATOR_PROP), ONE_NULL_OBJECT_PROP)

	/** The content/toArray "property" of the collections */
    public static val COLLECTION_CONTENT_PROP = BUILDER.newObjectProperty(
    	Collection, "content", typeof(Object[]), false, false, false,
    	[ if(it instanceof ContentOwner) content else toArray],
    	[obj,value|obj.clear;obj.addAll(Arrays.asList(value));obj], false)

	/** The empty virtual property of the collections */
    public static val COLLECTION_EMPTY_PROP = BUILDER.newBooleanProperty(
    	Collection, "empty", [empty], null, true)

	/** The size virtual property of the collections */
    public static val COLLECTION_SIZE_PROP = BUILDER.newIntegerProperty(
    	Collection, "size", [size], null, true)

	/** The Collection Type */
	public static val COLLECTION = BUILDER.newType(Collection,
		ListProvider.INSTANCE as Provider as Provider<Collection>, Kind.Trait, #[ITERABLE],
		<Property>newArrayList(COLLECTION_CONTENT_PROP, COLLECTION_EMPTY_PROP, COLLECTION_SIZE_PROP),
		ONE_NULL_OBJECT_PROP)

	/** The List Type */
	public static val LIST = BUILDER.newType(List, ListProvider.INSTANCE, Kind.Trait,
		#[COLLECTION], Property.NO_PROPERTIES, ONE_NULL_OBJECT_PROP)

	/** The Set Type */
	public static val SET = BUILDER.newType(Set, SetProvider.INSTANCE, Kind.Trait,
		#[COLLECTION], Property.NO_PROPERTIES, ONE_NULL_OBJECT_PROP)

	/** The empty virtual property of the Maps */
    public static val MAP_EMPTY_PROP = BUILDER.newBooleanProperty(
    	Map, "empty", [empty], null, true)

	/** The size virtual property of the Maps */
    public static val MAP_SIZE_PROP = BUILDER.newIntegerProperty(
    	Map, "size", [size], null, true)

	/** The iterator virtual property of the Map.entrySet */
    public static val MAP_ITERATOR_PROP = BUILDER.newObjectProperty(
    	Map, "iterator", Iterator, false, false, false, [entrySet.iterator], null, true)

	/** The Map Type */
	public static val MAP = BUILDER.newType(Map, MapProvider.INSTANCE, Kind.Trait,
		Type.NO_TYPE, <Property>newArrayList(MAP_EMPTY_PROP, MAP_SIZE_PROP), TWO_NULL_OBJECT_PROPS)

	/** The java.lang package */
	public static val JAVA_LANG_PACKAGE = BUILDER.newTypePackage(OBJECT, VOID,
		COMPARABLE, NUMBER, BOOLEAN, BYTE, CHARACTER, SHORT, INTEGER, LONG,
		FLOAT, DOUBLE, CHAR_SEQUENCE, STRING, ITERABLE
	)

	/** The java.io package */
	public static val JAVA_IO_PACKAGE = BUILDER.newTypePackage(SERIALIZABLE)

	/** The java.util package */
	public static val JAVA_UTIL_PACKAGE = BUILDER.newTypePackage(ITERATOR, COLLECTION, LIST, SET, MAP)

	/** The Hierarchy of Java's Runtime Types */
	public static val HIERARCHY = BUILDER.newHierarchy(JAVA_LANG_PACKAGE, JAVA_IO_PACKAGE, JAVA_UTIL_PACKAGE)

}

/**
 * The "Meta" constant-holding interface for the meta-types themselves.
 *
 * The call to JavaMeta.HIERARCHY.findType() in META_BASE forces the Java
 * Hierarchy to be initialized before the Meta Hierarchy.
 */
 @SuppressWarnings("rawtypes")
public interface Meta {
	/** The Hierarchy of Meta Types */
	public static val BUILDER = HierarchyBuilderFactory.registerHierarchyBuilder(new MetaHierarchyBuilder())

	/** The MetaBase Type */
	public static val META_BASE = BUILDER.newType(MetaBase, null, Kind.Data,
		#[JavaMeta.HIERARCHY.findType(Comparable)]
	)

	/** The TypePackage Type */
	public static val TYPE_PACKAGE = BUILDER.newType(TypePackage, null, Kind.Data, #[META_BASE])

	/** The Type Type */
	public static val Type<Type<?>> TYPE = BUILDER.newType(Type as Class, null, Kind.Data, #[META_BASE])

	/** The Property Type */
	public static val Type<Property<?,?>> PROPERTY = BUILDER.newType(Property as Class, null, Kind.Data, #[META_BASE])

	/** The meta package */
	public static val COM_BLOCKWITHME_META_PACKAGE = BUILDER.newTypePackage(
		META_BASE, TYPE_PACKAGE, TYPE, PROPERTY)

	/** The Hierarchy of Meta Types */
	public static val HIERARCHY = BUILDER.newHierarchy(COM_BLOCKWITHME_META_PACKAGE)
}
