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
package com.blockwithme.meta.types.impl;

import com.blockwithme.meta.impl.AbstractBuilder;
import com.blockwithme.meta.types.Kind;
import com.blockwithme.meta.types.TypeDef;

/**
 * @author monster
 *
 */
public class TypeBuilder extends AbstractBuilder {
    /** Creates a type from a class. */
    public TypeImpl build(final Factory fac, final Class<?> clazz) {
        final TypeDef annot = clazz.getAnnotation(TypeDef.class);
        if (annot == null) {
            throw new IllegalStateException(clazz
                    + " has no TypeDef annotation");
        }
        final BundleImpl bundle = fac.bundleFor(clazz);
        final TypeImpl result = fac.type(bundle, clazz.getName());
        result.type(clazz);
        result.kind(annot.kind());
        result.isArray(clazz.isArray());
        result.isData(annot.kind() == Kind.Data);
        result.isFinal(annot.kind() == Kind.Final);
        result.isImplementation(annot.kind() == Kind.Implementation);
        result.isRoot(annot.kind() == Kind.Root);
        result.isTrait(annot.kind() == Kind.Trait);
        // TODO: Validate against bundle configuration ...
        result.access(annot.access());
        if (result.isRoot()) {
            result.domain(result);
        }
        result.persistence(bundle, Long.MIN_VALUE, annot.persistence());

        result.directChildren();
        result.directParents();
        result.directProperties();

        // At resolve
        if (!result.isRoot()) {
            final Class<?> domain = annot.domain();
            result.domain(fac.type(fac.bundleFor(domain), domain.getName()));
        }
        result.allProperties();
        result.biggerThanParents(bundle, Long.MIN_VALUE, false);
        result.children();
        result.containers();
        result.parents();

        return result;
    }
}
