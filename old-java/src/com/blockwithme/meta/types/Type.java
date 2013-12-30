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

import java.util.List;

import com.tinkerpop.blueprints.Direction;
import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.modules.javahandler.JavaHandler;
import com.tinkerpop.frames.modules.typedgraph.TypeValue;

/**
 * Represents a fully resolved type. Normally, this means that there were no
 * conflict detected in the schema. A more detailed explanation of types can
 * be found in the documentation of <code>@Type<code>.
 *
 * @author monster
 */
@TypeValue("Type")
public interface Type extends Bundled, Named {

    /** The Java class representing this type. */
    @com.tinkerpop.frames.Property("implements")
    Class<?> getType();

    /** The Java class representing this type. */
    @com.tinkerpop.frames.Property("implements")
    void setType(final Class<?> type);

    /** The kind of type, that this class/interface is. */
    @com.tinkerpop.frames.Property("kind")
    Kind getKind();

    /** Sets the kind of type, that this class/interface is. */
    @com.tinkerpop.frames.Property("kind")
    void setKind(final Kind kind);

    /**
     * Data is for technical types without domain meaning, like Strings,
     * arrays, ... It cannot inherit, directly or indirectly, from a Root type.
     */
    @JavaHandler
    boolean isData();

    /** true only if it is an array (and therefore also a data). */
    @JavaHandler
    boolean isArray();

    /**
     * A Root type is at the base of an hierarchy of types.
     * It cannot inherit, directly or indirectly, from another Root type, or
     * Data type. Implicitly, a Root type also defines a Domain. A Domain is
     * useful to classify Data and Trait types, which cannot/don't have to,
     * extend a Root type. All type extending a Root type, are in that Domain.
     */
    @JavaHandler
    boolean isRoot();

    /**
     * A trait is a "partial type", which covers only one "shared aspect" of
     * multiple types. For example, Serialisable. It can be inherited by
     * anything.
     */
    @JavaHandler
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
    @JavaHandler
    boolean isImplementation();

    /**
     * A specialization is a sub-type of a Root type. It can only inherit,
     * directly or indirectly, from exactly one Root type. It cannot
     * inherit from a Data type.
     */
    @JavaHandler
    boolean isSpecialization();

    /**
     * A final type cannot have children outside it's bundle, and can only
     * have Implementations as child inside it's bundle.
     */
    @JavaHandler
    boolean isFinal();

    /** The access-level to this type. */
    @com.tinkerpop.frames.Property("access")
    Access getAccess();

    /** Sets the access-level to this type. */
    @com.tinkerpop.frames.Property("access")
    void setAccess(final Access access);

    /** List all direct properties of this type. */
    @Adjacency(label = "hasProperty")
    Iterable<Property> getDirectProperties();

    /** Adds a new direct property. */
    @Adjacency(label = "hasProperty")
    void addProperty(final Property property);

    /** Removes a direct property. */
    @Adjacency(label = "hasProperty")
    void removeProperty(final Property property);

    /** Returns the direct property with the given name, if any. */
    @GremlinGroovy("it.out('hasProperty').has('name',name)")
    Property findDirectProperty(@GremlinParam("name") final String name);

    /**
     * A child type is said to be <i>bigger</i> (in the sense of memory
     * footprint), when it defines new *properties*, in addition to the
     * existing properties of the parent types.
     */
    @com.tinkerpop.frames.Property("biggerThanParents")
    boolean isBiggerThanParents();

    /** Sets the final flag */
    @com.tinkerpop.frames.Property("biggerThanParents")
    void setBiggerThanParents(final boolean biggerThanParents);

    /** All the direct parents of this type. */
    @Adjacency(label = "extends")
    Iterable<Type> getDirectParents();

    /** Adds a new direct parent. */
    @Adjacency(label = "extends")
    void addParent(final Type parent);

    /** Removes a direct parent. */
    @Adjacency(label = "extends")
    void removeParent(final Type parent);

    /** Search for a direct parent with the given name, if any. */
    @GremlinGroovy("it.out('extends').has('name',name)")
    Type findDirectParent(@GremlinParam("name") final String name);

    /** Is the given other type a direct parent of this type? */
    @GremlinGroovy(value = "it.out('extends').count(otherType)==0", frame = false)
    boolean isDirectParent(@GremlinParam("otherType") final Type otherType);

    /** All the direct children of this type. */
    @Adjacency(label = "extends", direction = Direction.IN)
    Iterable<Type> getDirectChildren();

    /** Search for a direct child with the given name, if any. */
    @GremlinGroovy("it.in('extends').has('name',name)")
    Type findDirectChild(final String name);

    /** Is the given other type a direct child of this type? */
    @GremlinGroovy(value = "it.in('extends').count(otherType)==0", frame = false)
    boolean isDirectChild(@GremlinParam("otherType") final Type otherType);

    /** All the other types using this type. */
    @Adjacency(label = "usedBy")
    Iterable<Property> getContainers();

    /** Adds a new user. */
    @Adjacency(label = "usedBy")
    void addContainer(final Property user);

    /** Removes a user. */
    @Adjacency(label = "usedBy")
    void removeContainer(final Property user);

    /** The Domain of this type. Could be null for Data and Trait. */
    @Adjacency(label = "domain")
    Type getDomain();

    /** Sets the Domain of this type. Could be null for Data and Trait. */
    @Adjacency(label = "domain")
    void setDomain(final Type domain);

    /** The kinds of persistence supported by this type. */
    @com.tinkerpop.frames.Property("persistence")
    List<String> getPersistence();

    /** The kinds of persistence supported by this type. */
    @com.tinkerpop.frames.Property("persistence")
    void setPersistence(final List<String> persistence);

    // TODO Improve management of children and parents

//  /** List all the properties of this type. */
//  Property[] allProperties();
//
//  /** Returns the property with the given name, if any. */
//  Property findProperty(final String name);

//  /** All the parents of this type. */
//  Type[] parents();
//
//  /** Search for a parent with the given name, if any. */
//  Type findParent(final String name);
//
//  /** Is the given other type a parent of this type? */
//  boolean isParent(final Type otherType);

//  /** All the children of this type. */
//  Type[] children();
//
//  /** Search for a child with the given name, if any. */
//  Type findChild(final String name);
//
//  /** Is the given other type a child of this type? */
//  boolean isChild(final Type otherType);
}
