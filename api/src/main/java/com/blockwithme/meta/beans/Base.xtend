/*
 * Copyright (C) 2014 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License")
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
package com.blockwithme.meta.beans

import com.blockwithme.fn1.ProcObject
import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.ByteProperty
import com.blockwithme.meta.CharacterProperty
import com.blockwithme.meta.ContentOwner
import com.blockwithme.meta.DoubleProperty
import com.blockwithme.meta.FloatProperty
import com.blockwithme.meta.HierarchyBuilderFactory
import com.blockwithme.meta.IProperty
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.JavaMeta
import com.blockwithme.meta.Kind
import com.blockwithme.meta.LongProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.Property
import com.blockwithme.meta.PropertyMatcher
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.Type
import com.blockwithme.meta.TypeOwner
import com.blockwithme.meta.beans.impl._WitherImpl
import com.blockwithme.util.shared.AnyAccessor
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Objects
import java.util.Set
import java.util.logging.Logger

import static com.blockwithme.util.shared.Preconditions.*
import com.blockwithme.meta.util.Loggable

/** Base for all data/bean objects */
interface Bean extends TypeOwner, Loggable {
	/** Returns the true if the instance is immutable */
    def boolean isImmutable()

    /** Returns a full mutable copy */
    def Bean copy()

    /** Returns an immutable copy */
    def Bean snapshot()

    /** Returns a lightweight mutable copy */
    def Bean wrapper()
}

/**
 * "Internal" base for all data/bean objects.
 *
 * The "selected" state is usually used to keep track of the "dirty" state.
 */
interface _Bean extends Bean {
	/** Returns the current value of the change counter */
	def int getChangeCounter()

	/** Sets the current value of the change counter */
	def void setChangeCounter(int newValue)

	/** Returns the delegate, if any */
    def _Bean getDelegate()

	/** Sets the delegate (can be null) */
    def void setDelegate(_Bean delegate, boolean clearSelection,
            boolean alsoClearChangeCounter, boolean clearRecursively)

	/** Sets the delegate (can be null); does not clear selection */
    def void setDelegate(_Bean delegate)

	/** Returns the interceptor (cannot be null) */
    def Interceptor getInterceptor()

	/** Sets the interceptor (cannot be null) */
    def void setInterceptor(Interceptor newInterceptor)

    /** Returns the "parent" Bean, if any. */
    def _Bean getParentBean()

    /** Returns the key/index in the "parent", if any. */
    def Object getParentKey()

    /** Sets the "parent" Bean and optional key/index, if any. */
    def void setParentBeanAndKey(_Bean parent, Object key)

	/** Returns true, if some property was selected */
    def boolean isSelected()

	/** Returns true, if some property was selected, either in self, or in children */
    def boolean isSelectedRecursive()

	/** Returns true, if the specified property was selected */
    def boolean isSelected(Property<?,?> prop)

    /** Returns true if the specified property at the given index was selected */
    def boolean isSelected(int index)

	/** Marks the specified property as selected */
    def void setSelected(Property<?,?> prop)

	/** Marks the specified property at the given index as selected */
    def void setSelected(int index)

	/**
	 * Marks the specified property at the given index as selected,
	 * as well as all the properties that follow.
	 */
    def void setSelectedFrom(int index)

	/** Adds all the selected properties to "selected" */
    def void getSelectedProperty(Collection<Property<?,?>> selected)

	/** Cleans all selected flags */
    def void clearSelection(boolean alsoChangeCounter, boolean recursively)

	/** Sets all selected flags to true, including the children */
    def void setSelectionRecursive()

    /** Sets the immutable flag to true. */
    def void makeImmutable()

    /** Computes the JSON representation */
    def void toJSON(Appendable appendable)

    /** Returns the "root" Bean, if any. */
    def _Bean getRootBean()

    /** Updates the "root" Bean */
    def void updateRootBean()

    /** Returns true, if this Bean has the same (non-null) root as the Bean passed as parameter */
    def boolean hasSameRoot(_Bean other)

    /** Returns the index to use for this property. */
    def int indexOfProperty(Property<?, ?> prop)

    /**
     * Resolves a BeanPath to a value (including null, if the value, or any link, is null),
     * or fails, if failOnIncompatbileProperty is true, and an "incompatible" Property
     * is encountered along the way.
     */
    def Iterable<Object> resolvePath(BeanPath path, boolean failOnIncompatbileProperty)

    /** Reads the value(s) of this Property, and add them to values, if they match. */
    def void readProperty(IProperty<?, ?> p, Object[] keyMatcher, List<Object> values)

    /**
     * Resolves a "simple" path to a value (including null, if the value,
     * or any link, is null).
     * Will throw if the values types don't match the Properties.
     */
    def Object resolvePath(Property ... props)
}


/**
 * Wither is similar to a Bean, but is immutable and has "withX" instead of "setX" methods.
 */
interface Wither extends TypeOwner, Loggable {
	// Nothing so far
}


/** "Internal" base for all Wither objects. */
interface _Wither extends Wither {
    /** Computes the JSON representation */
    def void toJSON(Appendable appendable)
}


/**
 * Represents any number of "path", within a tree of Beans.
 *
 * Remember that paths can also "go up" by using the "parent" Property.
 */
final class BeanPath extends _WitherImpl {
	/**
	 * A PropertyMatcher, that matches either the Property representing
	 * the next step in a path, or representing the final value.
	 */
	public val PropertyMatcher propertyMatcher
	/**
	 * The optional list of matched keys/indexes, within the Property value,
	 * if the Property value is a Map/Collection, pointing to next step in a path,
	 * or representing the final value.
	 *
	 * A "null" matcher matches everything, and is required for non-maps/collections.
	 */
	public val Object[] keyMatcher
	/** The next link in the path, unless we are at the value, in which case it is null. */
	public val BeanPath next

  new(PropertyMatcher propertyMatcher, Object[] keyMatcher, BeanPath next) {
  	super(Meta.BEAN_PATH)
    this.propertyMatcher = Objects.requireNonNull(propertyMatcher, "propertyMatcher")
    this.keyMatcher = if ((keyMatcher !== null) && (keyMatcher.length == 0)) null else keyMatcher
    this.next = next
  }

  new(PropertyMatcher propertyMatcher, Object[] keyMatcher) {
    this(propertyMatcher, keyMatcher, null)
  }

  new(PropertyMatcher propertyMatcher, BeanPath next) {
    this(propertyMatcher, null, next)
  }

  new(PropertyMatcher propertyMatcher) {
    this(propertyMatcher, null, null)
  }

  /** Builds a full Bean path, from a list of Properties */
  def static BeanPath from(IProperty ... props) {
  	val len = props.length
  	var i = len-1
  	var BeanPath prev = null
  	while (i >= 0) {
  		val p = props.get(i--) as IProperty
  		prev = new BeanPath(p, prev)
  	}
  	prev
  }
}


/**
 * The "context" within which an Entity exists.
 * It could be a JPA table, or anything that contains entities.
 *
 * I want Entity to be "generic"; it might come from an SQL table, or from Redis,
 * or from a "property file"; it does not matter. For each "context" that might
 * be the source of entities, the "right" kind of ID might be something completely
 * different; a "long", a "UUID", a "file-path" ... And it probably makes sense
 * to keep whatever is that entity ID, within that entity, into the most appropriate
 * form there is (as a primitive long, as a UUID instance, as a File, ...)
 * So I don't want to force any specific ID form onto the Entity, but I need
 * some kind of universal representation for those IDs. Something that can be
 * serialized, by another entity, even if that other entity lives in a different
 * context. So the entity context is there to make sure we can turn and entity ID
 * to a String, and also to a URN, which allows specifying the ID AND the context
 * in a single String.
 *
 * We will make the simplifying assumption that *IDs never change*, nor does the
 * hosting context.
 *
 * A URN for an Entity can be composed as: namespace+":"+unique-ID
 */
interface EntityContext {
	/** Returns the unique namespace for this entity context. */
	def String getNamespace()

	/**
	 * Returns the unique ID (within this context) of the entity.
	 * Null maps to null.
	 */
	def String getIDAsString(Entity entity)

	/**
	 * Finds/loads/creates/.. an entity, based on it's ID.
	 * The actual entity might, or not, be currently available.
	 */
	def Handle getEntityFromID(String idAsString)

	/**
	 * Requests, that the requested Entity be loaded, and the requester be informed
	 * when it happens (or fails).
	 *
	 * requester and onLoad can be null, in case you don't care when it's loaded.
	 *
	 * requester specifies who requested the load, so that onLoad be called in the
	 * right thread (We assume Entities are tied to a specific thread, as they are NOT
	 * thread-safe, and that whatever implements an EntityContext knows how to sort this
	 * out).
	 *
	 * onLoad will be passed an Exception, if the load fails.
	 */
	def void requestLoad(Handle requested, Handle requester, ProcObject<Object> onLoad)
}

/**
 * An Handle to an Entity.
 *
 * The Handle enables an object to reference an Entity, even if it is not loaded
 * yet, or if it is loaded somewhere else, and therefore cannot be loaded here too.
 *
 * An Handle ties an Entity to an EntityContext, and should provide the
 * information any EntityContext needs, to access the referenced Entity
 * in a thread-safe way.
 */
class Handle {
	/** The ID-as-String of the Entity */
	public val String id
	/** The entity context */
	public val EntityContext context
	/** toString */
	val String toString
	/** hashCode */
	val int hashCode
	/** The current reference to the Entity */
	var volatile Entity entity
	/** Constructor */
	new(String id, EntityContext context) {
		this.id = requireNonEmpty(id, "id")
		this.context = requireNonNull(context, "context")
		toString = context.namespace+":"+id
		hashCode = toString.hashCode
	}
	/** Returns the reference to the Entity. It might be currently null. */
	final def Entity getEntity() {
		entity
	}
	/** Sets the reference to the Entity. It can be null. */
	final def void setEntity(Entity entity) {
		this.entity = entity
	}
	/** toString */
	final override toString() {
		toString
	}
	/** Hashcode */
	final override hashCode() {
		hashCode
	}
}

/**
 * Entities are beans that have a "independent lifecycle".
 * If an Entity is the root of a Bean tree, it "owns" that tree.
 * Otherwise, it is just "referenced" by the tree.
 *
 * TODO An Entity should support a standard request, where it receives
 * a Provider for a View (a new interface that must extend Bean, and define
 * an initView(? extends Entity) method), create the View, call it's initView()
 * with this as parameter, and then return the View as a reply. This should
 * even work across JVMs, if the Provider can be resolved, and the serialization
 * of Beans is automatic.
 *
 * TODO If we implement transactional Beans (the control over the transaction must
 * run over the Entity), then we must also be able to change things like the "parent"
 * transactionally, and this must still work, with multiple changes to the same field
 * within the same transaction. And object/tree-global validation must come right
 * before the commit.
 *
 * TODO If an error comes *during* the commit, as opposed to before the commit,
 * which is when the validation runs, then there is no saying what the state of
 * the objects are, and so I have to reload the whole tree.
 *
 * TODO With transactions, property change events can only ever be fired, if at all,
 * after a successful commit, because otherwise, nothing changed and so there is
 * no change to fire. And this means we could bundle all the changes in one single
 * fire event (request). But to fire, one has to clearly identify the source of
 * the event, and that might not be easy, in particular across the network.
 *
 * TODO If we define an interface representing an object that records changes for
 * transactions, we could have two implementations, one that is NO-OP, such that
 * the generated code is always the same, and we just swap the transaction manager
 * to choose transactions or not. Maybe we just need multiple Interceptors, to take
 * care of that, but this only really works if we store changes in a separate "map"
 * (Property, [Key/Index], OldValue), because it would be stupid to double all the
 * fields to allow transaction, but then not use them.
 */
interface Entity extends Bean {
	/** Returns the Entity Handle */
	def Handle getHandle()
}

/**
 * "Internal" Entity interface.
 */
interface _Entity extends Entity, _Bean {
	/** Sets the Entity Handle, if it wasn't set yet, or fails. */
	def void setHandle(Handle handle)

	/** Returns the creation time in milliseconds */
	def long getCreationTime()

	/** Sets the creation time in milliseconds */
	def void setCreationTime(long creationTime)

	/** Returns the last modification time in milliseconds */
	def long getLastModificationTime()

	/** Sets the last modification time in milliseconds */
	def void setLastModificationTime(long lastModificationTime)
}

/** Interceptor allows "delegation", "validation", ... */
interface Interceptor {
	/** Intercept the read access to a boolean property */
    def boolean getBooleanProperty(_Bean instance, BooleanProperty<?,?,?> prop, boolean value)

	/** Intercept the write access to a boolean property */
    def boolean setBooleanProperty(_Bean instance, BooleanProperty<?,?,?> prop, boolean oldValue,
            boolean newValue)

	/** Intercept the read access to a byte property */
    def byte getByteProperty(_Bean instance, ByteProperty<?,?,?> prop, byte value)

	/** Intercept the write access to a boolean property */
    def byte setByteProperty(_Bean instance, ByteProperty<?,?,?> prop, byte oldValue,
            byte newValue)

	/** Intercept the read access to a char property */
    def char getCharacterProperty(_Bean instance, CharacterProperty<?,?,?> prop, char value)

	/** Intercept the write access to a char property */
    def char setCharacterProperty(_Bean instance, CharacterProperty<?,?,?> prop, char oldValue,
            char newValue)

	/** Intercept the read access to a short property */
    def short getShortProperty(_Bean instance, ShortProperty<?,?,?> prop, short value)

	/** Intercept the write access to a short property */
    def short setShortProperty(_Bean instance, ShortProperty<?,?,?> prop, short oldValue,
            short newValue)

	/** Intercept the read access to a int property */
    def int getIntegerProperty(_Bean instance, IntegerProperty<?,?,?> prop, int value)

	/** Intercept the write access to a int property */
    def int setIntegerProperty(_Bean instance, IntegerProperty<?,?,?> prop, int oldValue,
            int newValue)

	/** Intercept the read access to a float property */
    def float getFloatProperty(_Bean instance, FloatProperty<?,?,?> prop, float value)

	/** Intercept the write access to a float property */
    def float setFloatProperty(_Bean instance, FloatProperty<?,?,?> prop, float oldValue,
            float newValue)

	/** Intercept the read access to a double property */
    def double getDoubleProperty(_Bean instance, DoubleProperty<?,?,?> prop, double value)

	/** Intercept the write access to a double property */
    def double setDoubleProperty(_Bean instance, DoubleProperty<?,?,?> prop, double oldValue,
            double newValue)

	/** Intercept the read access to a long property */
    def long getLongProperty(_Bean instance, LongProperty<?,?,?> prop, long value)

	/** Intercept the write access to a long property */
    def long setLongProperty(_Bean instance, LongProperty<?,?,?> prop, long oldValue,
            long newValue)

	/** Intercept the read access to a Object property */
    def <E> E getObjectProperty(_Bean instance, ObjectProperty<?,E,?,?> prop, E value)

	/** Intercept the write access to a Object property */
    def <E> E setObjectProperty(_Bean instance, ObjectProperty<?,E,?,?> prop, E oldValue,
            E newValue)
}

/** Interceptor for collections of objects */
interface ObjectCollectionInterceptor<E> extends Interceptor {
	/** Intercept the read access to a Object element in a collection */
    def E getObjectAtIndex(_CollectionBean<E> instance, int index, E value)

	/** Intercept the write access to a Object element in a collection */
    def E setObjectAtIndex(_CollectionBean<E> instance, int index, E oldValue,
            E newValue)

	/** Intercept the insert access to a Object element in a collection */
    def E addObjectAtIndex(_CollectionBean<E> instance, int index, E newValue, boolean followingElementsChanged)

	/** Intercept the remove access to a Object element in a collection */
    def void removeObjectAtIndex(_CollectionBean<E> instance, int index, E value, boolean followingElementsChanged)

	/** Intercept the clear to a collection */
    def void clear(_CollectionBean<E> instance)

}

/** Interceptor for Map of objects */
interface ObjectObjectMapInterceptor<K,V> extends Interceptor {
	/** Intercept the read access to a Object key in a Map */
    def K getKeyAtIndex(_MapBean<K, V> instance, int index, K key)

	/** Intercept the read access to a Object value in a Map */
    def V getValueAtIndex(_MapBean<K, V> instance, int index, V value)

	/** Intercept the write access to a Object key in a Map */
    def K setKeyAtIndex(_MapBean<K, V> instance, int index, K oldKey,
            K newKey)

	/** Intercept the write access to a Object value in a Map */
    def V setValueAtIndex(_MapBean<K, V> instance, K key, int index, V oldValue,
            V newValue)

	/** Intercept the clear to a Map */
    def void clear(_MapBean<K, V> instance)

}

/** A Bean that represents a Collection (either List or Set) */
interface CollectionBean<E> extends Collection<E>, ContentOwner<E>, Bean {
    /** Returns the CollectionBeanConfig */
    def CollectionBeanConfig getConfig()
    /** Returns the value Type (E) */
    def Type<E> getValueType()
}

/** A Bean that represents a List */
interface ListBean<E> extends List<E>, CollectionBean<E> {
}

/** A Bean that represents a Set */
interface SetBean<E> extends Set<E>, CollectionBean<E> {
}

/** A Bean that represents a Collection (either List or Set) */
interface _CollectionBean<E> extends CollectionBean<E>, _Bean {
	/** Returns the delegate, if any */
    override _CollectionBean<E> getDelegate()
}

/** A Bean that represents a List */
interface _ListBean<E> extends ListBean<E>, _CollectionBean<E> {
	/** Returns the delegate, if any */
    override _ListBean<E> getDelegate()
}

/** A Bean that represents a Set */
interface _SetBean<E> extends SetBean<E>, _CollectionBean<E> {
	/** Returns the delegate, if any */
    override _SetBean<E> getDelegate()
    /** Clears the collection, if it only contains null. Returns true on success. */
    def boolean clearIfEffectivelyEmpty()
}

/** A Bean that represents a Map (always an HashMap) */
interface MapBean<K,V> extends Map<K,V>, ContentOwner<Map.Entry<K,V>>, Bean {
    /** Returns the key Type (K) */
    def Type<K> getKeyType()
    /** Returns the value Type (V) */
    def Type<V> getValueType()
}

/** A Bean that represents a Map (always an HashMap) */
interface _MapBean<K,V> extends MapBean<K,V>, _Bean {
	/** Returns the delegate, if any */
    override _MapBean<K,V> getDelegate()
}

/** An immutable Reference to an immutable Bean. */
final class Ref<E extends Bean> extends _WitherImpl {
	public final E value

	new(E newValue) {
		super(Meta.REF)
		if ((newValue !== null) && !newValue.immutable) {
			throw new IllegalArgumentException("Reference must be immutable: "+newValue)
		}
		value = newValue
	}
}

/** Represents a Property change event, within a Bean */
class PropChangeEvent {
	/** Accessor for the old value. */
	public static val OLD = new AnyAccessor<PropChangeEvent> {
		override getDoubleUnsafe(PropChangeEvent holder) {
			holder.primitiveOldValue
		}

		override getObjectUnsafe(PropChangeEvent holder) {
			holder.objectOldValue
		}

		override protected setObjectPrimitive(PropChangeEvent holder, Object object, double primitive) {
			holder.objectOldValue = object
			holder.primitiveOldValue = primitive
		}
	}
	/** Accessor for the new value. */
	public static val NEW = new AnyAccessor<PropChangeEvent> {
		override getDoubleUnsafe(PropChangeEvent holder) {
			holder.primitiveNewValue
		}

		override getObjectUnsafe(PropChangeEvent holder) {
			holder.objectNewValue
		}

		override protected setObjectPrimitive(PropChangeEvent holder, Object object, double primitive) {
			holder.objectNewValue = object
			holder.primitiveNewValue = primitive
		}
	}
	/** Accessor for the Property key/index, if any. */
	public static val KEY = new AnyAccessor<PropChangeEvent> {
		override getDoubleUnsafe(PropChangeEvent holder) {
			holder.primitiveKey
		}

		override getObjectUnsafe(PropChangeEvent holder) {
			holder.objectKey
		}

		override protected setObjectPrimitive(PropChangeEvent holder, Object object, double primitive) {
			holder.objectKey = object
			holder.primitiveKey = primitive
		}
	}
	/** The event source */
	public val _Bean source
	/** The Property */
	public val Property<?,?> property
	/** The old value, if primitive */
	package var double primitiveOldValue
	/** The new value, if primitive */
	package var double primitiveNewValue
	/** The Property key/index, if any, if primitive */
	package var double primitiveKey
	/** The old value, if Object */
	package var Object objectOldValue
	/** The new value, if Object */
	package var Object objectNewValue
	/** The Property key/index, if any, if Object */
	package var Object objectKey

	/** The constructor. */
	new(_Bean source, Property<?,?> property) {
		this.source = requireNonNull(source, "source")
		this.property = requireNonNull(property, "property")
	}
}

/**
 * The "Meta" constant-holding interface for the meta-types themselves.
 *
 * The call to JavaMeta.HIERARCHY.findType() in META_BASE forces the Java
 * Hierarchy to be initialized before the Meta Hierarchy.
 */
 @SuppressWarnings("rawtypes")
interface Meta {
	/** The Hierarchy of Meta Types */
	val BUILDER = HierarchyBuilderFactory.getHierarchyBuilder(Bean.name)

	/** The Bean Type */
	val BEAN = BUILDER.newType(Bean, null, Kind.Trait, null, null, #[com.blockwithme.meta.util.Meta.LOGGABLE])

	/**
	 * The change counter Bean property.
	 * It would be good if this property was serialized. But we have to define
	 * it as virtual, otherwise it gets used in "equals()".
	 */
    val _BEAN__CHANGE_COUNTER = BUILDER.newIntegerProperty(
    	_Bean, "changeCounter", [changeCounter], [obj,value|obj.changeCounter = value;obj], true)

	/**
	 * The parent virtual Bean property.
	 * Listeners will be informed of change after both parentBean, parentKey and rootBean were updated.
	 */
    val _BEAN__PARENT_BEAN = BUILDER.newObjectProperty(
    	_Bean, "parentBean", _Bean, true, true, false, false, [parentBean], null, true)

	/** The parent "key" virtual Bean property */
    val _BEAN__PARENT_KEY = BUILDER.newObjectProperty(
    	_Bean, "parentKey", Object, true, true, false, false, [parentKey], null, true)

	/** The root virtual Bean property */
    val _BEAN__ROOT_BEAN = BUILDER.newObjectProperty(
    	_Bean, "rootBean", _Bean, true, true, false, false, [rootBean], null, true)

	/** The _Bean Type */
	val _BEAN = BUILDER.newType(_Bean, null, Kind.Trait, null, null, #[BEAN],
		Meta._BEAN__CHANGE_COUNTER,
		Meta._BEAN__PARENT_BEAN,
		Meta._BEAN__PARENT_KEY,
		Meta._BEAN__ROOT_BEAN)

	/** The Entity Type */
	val ENTITY = BUILDER.newType(Entity, null, Kind.Trait, null, null, #[BEAN])

	/** The _Entity Type */
	val _ENTITY = BUILDER.newType(_Entity, null, Kind.Trait, null, null, #[ENTITY, _BEAN])

	/** The Bean Type */
	val WITHER = BUILDER.newType(Wither, null, Kind.Trait, null, null)

	/** The _Bean Type */
	val _WITHER = BUILDER.newType(_Wither, null, Kind.Trait, null, null, #[WITHER])

	/** The value Ref property */
    val REF__VALUE = BUILDER.newObjectProperty(
    	Ref, "value", _Bean, true, true, true, true, [value], null, false)

	/** The Ref Type */
	val REF = BUILDER.newType(Ref, null, Kind.Data, null, null, #[_WITHER], Meta.REF__VALUE)

	/** The BeanPath Type */
	val BEAN_PATH = BUILDER.newType(BeanPath, null, Kind.Data, null, null, #[_WITHER])

	/** The id CollectionBeanConfig property */
	val COLLECTION_BEAN_CONFIG__ID = BUILDER.newIntegerProperty(CollectionBeanConfig, "id", [id], null, false)

	/** The CollectionBeanConfig Type; we pretend it has no property. */
	val COLLECTION_BEAN_CONFIG = BUILDER.newType(CollectionBeanConfig, null, Kind.Data, null, null, #[_WITHER], Meta.COLLECTION_BEAN_CONFIG__ID)

	/** The configuration property of the collection beans */
    val COLLECTION_BEAN__CONFIG = BUILDER.newObjectProperty(
    	CollectionBean, "config", CollectionBeanConfig, true, true, true, false, [config], null, false)

	/** The value-type property of the collection beans */
    val COLLECTION_BEAN__VALUE_TYPE = BUILDER.newObjectProperty(
    	CollectionBean, "valueType", Type, true, true, true, false, [valueType], null, false)

	/** The CollectionBean Type */
	val COLLECTION_BEAN = BUILDER.newType(CollectionBean, null, Kind.Trait, null, null,
		#[_BEAN, JavaMeta.LIST, JavaMeta.SET], <Property>newArrayList(COLLECTION_BEAN__CONFIG),
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The ListBean Type */
	val LIST_BEAN = BUILDER.newType(ListBean, null, Kind.Trait, null, null,
		#[COLLECTION_BEAN, JavaMeta.LIST], Property.NO_PROPERTIES,
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The SetBean Type */
	val SET_BEAN = BUILDER.newType(SetBean, null, Kind.Trait, null, null,
		#[COLLECTION_BEAN, JavaMeta.SET], Property.NO_PROPERTIES,
		COLLECTION_BEAN__VALUE_TYPE as ObjectProperty)

	/** The key-type property of the Map beans */
    val MAP_BEAN__KEY_TYPE = BUILDER.newObjectProperty(
    	MapBean, "keyType", Type, true, true, true, false, [keyType], null, false)

	/** The value-type property of the Map beans */
    val MAP_BEAN__VALUE_TYPE = BUILDER.newObjectProperty(
    	MapBean, "valueType", Type, true, true, true, false, [valueType], null, false)

	/** The MapBean Type */
	val MAP_BEAN = BUILDER.newType(MapBean, null, Kind.Trait, null, null,
		#[_BEAN, JavaMeta.MAP], Property.NO_PROPERTIES, MAP_BEAN__KEY_TYPE as ObjectProperty,
		MAP_BEAN__VALUE_TYPE as ObjectProperty)

	/** The Beans package */
	val COM_BLOCKWITHME_META_BEANS_PACKAGE = BUILDER.newTypePackage(
		BEAN, _BEAN, ENTITY, _ENTITY, COLLECTION_BEAN_CONFIG, COLLECTION_BEAN,
		LIST_BEAN, SET_BEAN, MAP_BEAN, WITHER, _WITHER, REF, BEAN_PATH)

	/** The Hierarchy of Meta Types */
	val HIERARCHY = BUILDER.newHierarchy(COM_BLOCKWITHME_META_BEANS_PACKAGE)
}
