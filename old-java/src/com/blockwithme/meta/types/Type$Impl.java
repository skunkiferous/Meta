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

import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.frames.modules.javahandler.JavaHandlerContext;

/**
 * @author monster
 *
 */
public abstract class Type$Impl implements JavaHandlerContext<Vertex>, Type {

    /**
     * Data is for technical types without domain meaning, like Strings,
     * arrays, ... It cannot inherit, directly or indirectly, from a Root type.
     */
    @Override
    public boolean isData() {
        return (getKind() == Kind.Data) || isArray();
    }

    /** true only if it is an array (and therefore also a data). */
    @Override
    public boolean isArray() {
        return getKind() == Kind.Array;
    }

    /**
     * A Root type is at the base of an hierarchy of types.
     * It cannot inherit, directly or indirectly, from another Root type, or
     * Data type. Implicitly, a Root type also defines a Domain. A Domain is
     * useful to classify Data and Trait types, which cannot/don't have to,
     * extend a Root type. All type extending a Root type, are in that Domain.
     */
    @Override
    public boolean isRoot() {
        return getKind() == Kind.Root;
    }

    /**
     * A trait is a "partial type", which covers only one "shared aspect" of
     * multiple types. For example, Serialisable. It can be inherited by
     * anything.
     */
    @Override
    public boolean isTrait() {
        return getKind() == Kind.Trait;
    }

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
    @Override
    public boolean isImplementation() {
        return getKind() == Kind.Implementation;
    }

    /**
     * A specialization is a sub-type of a Root type. It can only inherit,
     * directly or indirectly, from exactly one Root type. It cannot
     * inherit from a Data type.
     */
    @Override
    public boolean isSpecialization() {
        return (getKind() == Kind.Specialization) || isFinal();
    }

    /**
     * A final type cannot have children outside it's bundle, and can only
     * have Implementations as child inside it's bundle.
     */
    @Override
    public boolean isFinal() {
        return getKind() == Kind.Final;
    }
}
