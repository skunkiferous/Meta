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
package com.blockwithme.meta.annotations;

import java.lang.annotation.Annotation;
import java.util.Map;

import org.reflections.Reflections;

/**
 * The Annotation Reader reads the annotations on a Java type, processing the
 * content into a recursive Map-based structure. Some conversion can be
 * performed automatically, like instantiating classes.
 *
 * @author monster
 */
public interface AnnotationReader {
    /**
     * Registers a value converter for a specific property of a specific annotation.
     *
     * Example: A converter for actualInstance in TypeRangeDef:
     *
     * public @interface TypeRangeDef {
     *     boolean actualInstance() default false;
     * }
     *
     * Would be registered like this:
     *
     * reader.withPropertyConverter(TypeRangeDef.class,"actualInstance");
     */
    <ANNOTATION> AnnotationReader withPropertyConverter(
            final Class<ANNOTATION> annotationType, final String property,
            final Converter<?, ANNOTATION, ?> converter);

    /**
     * Registers a value converter for any property of any annotation, where
     * the property in the annotation itself is annotated with the given
     * annotation type.
     *
     * Example: A converter for Class<?> (to instances):
     *
     * public @interface TypeRangeDef {
     *     @Instantiate
     *     Class<?>[] children() default {};
     * }
     *
     * Would be registered like this:
     *
     * reader.withValueConverter(Instantiate.class,Class<?>[].class);
     */
    <ANNOTATION, VALUE> AnnotationReader withValueConverter(
            final Class<ANNOTATION> annotationType,
            final Class<VALUE> valueType, final Converter<VALUE, ?, ?> converter);

    /** Registers a type Post-Processor. */
    AnnotationReader withPostProcessor(final TypeProcessor postProcessor);

    /** Registers an annotation Post-Processor. */
    <ANNOTATION> AnnotationReader withPostProcessor(
            final Class<ANNOTATION> annotationType,
            final AnnotationProcessor<ANNOTATION, ?> postProcessor);

    /** Reads all the annotations on a type. */
    AnnotatedType read(final Class<?> type);

    /**
     * Finds all types annotated with at least one of the given annotations,
     * and reads their annotations. The result is a sorted map from class name
     * to annotation data. Note the the map contain the complete data,
     * including data on annotations not part of the method parameters.
     */
    Map<String, AnnotatedType> read(
            final Reflections reflections,
            @SuppressWarnings("unchecked") final Class<? extends Annotation>... annotations);
}
