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

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationProcessor;
import com.blockwithme.meta.annotations.PropMap;
import com.blockwithme.meta.types.annotations.Property;

/**
 * @author monster
 *
 */
public class PropertyAnnotationProcessor implements
        AnnotationProcessor<Property, Method> {
    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationProcessor#process(com.blockwithme.meta.annotations.PropMap, com.blockwithme.meta.annotations.AnnotatedType, java.lang.Object, java.lang.reflect.AnnotatedElement, com.blockwithme.meta.annotations.PropMap)
     */
    @Override
    public void process(final PropMap context,
            final AnnotatedType annotatedType,
            final Property annotatedTypeAnnotation,
            final Method annotatedElement, final PropMap annotationData) {
        String name = annotatedElement.getName();
        if (name.startsWith("is") && (name.length() > 2)
                && Character.isUpperCase(name.charAt(2))) {
            name = Character.toLowerCase(name.charAt(2)) + name.substring(3);
        } else if ((name.startsWith("get") || name.startsWith("set")
                || name.startsWith("has") || name.startsWith("can"))
                && (name.length() > 3) && Character.isUpperCase(name.charAt(3))) {
            name = Character.toLowerCase(name.charAt(3)) + name.substring(4);
        }
        annotationData.put("name", name);
    }
}
