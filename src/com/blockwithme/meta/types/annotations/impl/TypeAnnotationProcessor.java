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
package com.blockwithme.meta.types.annotations.impl;

import java.lang.reflect.Method;
import java.util.Map;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationProcessor;
import com.blockwithme.meta.annotations.PropMap;
import com.blockwithme.meta.types.Kind;
import com.blockwithme.meta.types.annotations.Property;
import com.blockwithme.meta.types.annotations.Type;

/**
 * @author monster
 *
 */
public class TypeAnnotationProcessor implements
        AnnotationProcessor<Type, Class<?>> {
    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationProcessor#process(com.blockwithme.meta.annotations.PropMap, com.blockwithme.meta.annotations.AnnotatedType, java.lang.Object, java.lang.reflect.AnnotatedElement, com.blockwithme.meta.annotations.PropMap)
     */
    @Override
    public void process(final PropMap context,
            final AnnotatedType annotatedType,
            final Type annotatedTypeAnnotation,
            final Class<?> annotatedElement, final PropMap annotationData) {
        annotationData.put("implements", annotatedElement);
        annotationData.put("name", annotatedElement.getName());
        final Kind kind = annotationData.get("kind", Kind.class);
        final boolean array = annotatedType.getType().isArray();
        annotationData.put("array", array);
        annotationData.put("data", array || (kind == Kind.Data));
        annotationData.put("final", kind == Kind.Final);
        annotationData.put("implementation", kind == Kind.Implementation);
        annotationData.put("root", kind == Kind.Root);
        annotationData.put("specialization", kind == Kind.Specialization);
        annotationData.put("trait", kind == Kind.Trait);
        boolean biggerThanParents = false;
        for (final Method m : annotatedType.getMethods()) {
            final Map<Class<?>, PropMap> map = annotatedType.getMethodData(m);
            final PropMap pm = map.get(Property.class);
            if (pm != null) {
                biggerThanParents = true;
                break;
            }
        }
        annotationData.put("biggerThanParents", biggerThanParents);
    }
}
