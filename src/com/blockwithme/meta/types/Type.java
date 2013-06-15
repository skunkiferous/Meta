/*
 * Copyright (C) 2013 Sebastien Diot.
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
package com.blockwithme.meta.types;

import com.blockwithme.meta.Definition;

/**
 * Represents a fully resolved type. Normally, this means that there were no
 * conflict detected in the schema. A more detailed explanation of types can
 * be found in the documentation of <code>TypeDef<code>.
 *
 * @author monster
 */
public interface Type extends Definition<Type>, Bundled<Type> {
    /** The Java class representing this type. */
    Class<?> type();

    /**
     * Data is for technical types without domain meaning, like Strings,
     * arrays, ... It cannot inherit, directly or indirectly, from a Root type.
     */
    boolean isData();

    /** true only if it is an array (and therefore also a data). */
    boolean isArray();

    /**
     * A Root type is at the base of an hierarchy of types.
     * It cannot inherit, directly or indirectly, from another Root type, or
     * Data type. Implicitly, a Root type also defines a Domain. A Domain is
     * useful to classify Data and Trait types, which cannot/don't have to,
     * extend a Root type. All type extending a Root type, are in that Domain.
     */
    boolean isRoot();

    /**
     * A trait is a "partial type", which covers only one "shared aspect" of
     * multiple types. For example, Serialisable. It can be inherited by
     * anything.
     */
    boolean isTrait();

    /**
     * An Implementation is the, potentially abstract, realization of some
     * non-Data type. It must not define any "interface" itself, but only
     * implement interfaces defined in other types. It can be abstract, and
     * can also extend from some other Implementation.
     *
     * A Trait Implementation could be a special case that can only be defined
     * using static methods, taking the Trait as first parameter. Or, it would
     * be conceivable to define a Trait together with it's Implementation as
     * an abstract class.
     *
     * An Implementation is concrete, when it implements every of it's parent
     * Types methods.
     */
    boolean isImplementation();

    /**
     * A final type cannot have children outside it's bundle, and can only
     * have Implementations as child inside it's bundle.
     */
    boolean isFinal();

    /** The kind of type, that this class/interface is. */
    Kind kind();

    /** The access-level to this type. */
    Access access();

    /**
     * A child type is said to be <i>bigger</i> (in the sense of memory
     * footprint), when it defines new *properties*, in addition to the
     * existing properties of the parent types.
     */
    boolean biggerThanParents(final Long time);

    /** List all the properties of this type. */
    Property[] allProperties(final Long time);

    /** Returns the property with the given name, if any. */
    Property findProperty(final Long time, final String name);

    /** List all direct properties of this type. */
    Property[] directProperties(final Long time);

    /** Returns the direct property with the given name, if any. */
    Property findDirectProperty(final Long time, final String name);

    /** All the parents of this type. */
    Type[] parents(final Long time);

    /** Search for a parent with the given name, if any. */
    Type findParent(final Long time, final String name);

    /** All the direct parents of this type. */
    Type[] directParents(final Long time);

    /** Search for a direct parent with the given name, if any. */
    Type findDirectParent(final Long time, final String name);

    /** Is the given other type a parent of this type? */
    boolean isParent(final Long time, final Type otherType);

    /** Is the given other type a direct parent of this type? */
    boolean isDirectParent(final Long time, final Type otherType);

    /** All the children of this type. */
    Type[] children(final Long time);

    /** Search for a child with the given name, if any. */
    Type findChild(final Long time, final String name);

    /** All the direct children of this type. */
    Type[] directChildren(final Long time);

    /** Search for a direct child with the given name, if any. */
    Type findDirectChild(final Long time, final String name);

    /** Is the given other type a child of this type? */
    boolean isChild(final Long time, final Type otherType);

    /** Is the given other type a direct child of this type? */
    boolean isDirectChild(final Long time, final Type otherType);

    /** All the other types containing this type. */
    Container[] containers(final Long time);

    /** Is the given other type a container of this type? */
    Container[] findContainer(final Long time, final Type otherType);

    /** The Domain of this type. Could be null for Data and Trait. */
    Type domain();

    /** The kinds of persistence supported by this type. */
    String[] persistence(final Long time);
}
