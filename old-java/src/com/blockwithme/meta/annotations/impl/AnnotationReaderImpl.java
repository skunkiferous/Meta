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
package com.blockwithme.meta.annotations.impl;

import java.lang.annotation.Annotation;
import java.lang.reflect.AnnotatedElement;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;

import org.reflections.Reflections;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationProcessor;
import com.blockwithme.meta.annotations.AnnotationReader;
import com.blockwithme.meta.annotations.Converter;
import com.blockwithme.meta.annotations.Instantiate;
import com.blockwithme.meta.annotations.PropMap;
import com.blockwithme.meta.annotations.TypeProcessor;

/**
 * An AnnotationReader implementation.
 *
 * TODO Add auto-registration of the processors/converters ...
 * (By using special annotations on them too, that are searched for at runtime)
 *
 * TODO We should have a "Properties" Value-converter, where an array of Strings
 * in the form: {"age:int(5)","type:class(com.test.Test)", ...} can be defined,
 * and annotated with @Properties and automatically converted to a property map,
 * and added as a sub-map to the current annotation.
 *
 * TODO We used singletonMap() as Key-Value-Pair map key, out of laziness.
 * We should replace it with something more efficient, like a "Tuple".
 *
 * @author monster
 */
public class AnnotationReaderImpl implements AnnotationReader {
    /** All the PostProcessors. */
    private final List<TypeProcessor> postProcessors = new ArrayList<>();

    /** All the property converters. */
    @SuppressWarnings("rawtypes")
    private final Map<Map<Class<?>, String>, Converter> propertyConverters = new HashMap<>();

    /** All the value converters. */
    @SuppressWarnings("rawtypes")
    private final Map<Map<Class<?>, Class<?>>, Converter> valueConverters = new HashMap<>();

    /** All the annotation methods. */
    private final Map<Class<?>, Method[]> annotationMethods = new HashMap<>();

    /** All the annotation processors. */
    @SuppressWarnings("rawtypes")
    private final Map<Class<?>, AnnotationProcessor> annotationProcessors = new HashMap<>();

    /** The context. */
    private final PropMap context;

    /**
     * Creates an AnnotationReader with the given context.
     */
    @SuppressWarnings("unchecked")
    public AnnotationReaderImpl(final PropMap context) {
        this.context = context;
        // Instantiate is always registered.
        @SuppressWarnings("rawtypes")
        final Instantiator converter = new Instantiator<>();
        withValueConverter(Instantiate.class, String.class, converter);
        withValueConverter(Instantiate.class, String[].class, converter);
        withValueConverter(Instantiate.class, Class.class, converter);
        withValueConverter(Instantiate.class, Class[].class, converter);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#withPropertyConverter(java.lang.Class, java.lang.String, com.blockwithme.meta.annotations.Converter)
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    @Override
    public <ANNOTATION> AnnotationReader withPropertyConverter(
            final Class<ANNOTATION> annotationType, final String property,
            final Converter<?, ANNOTATION, ?> converter) {
        final Map key = Collections.singletonMap(
                Objects.requireNonNull(annotationType, "annotationType"),
                Objects.requireNonNull(property, "property"));
        propertyConverters.put(key,
                Objects.requireNonNull(converter, "converter"));
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#withValueConverter(java.lang.Class, java.lang.Class, com.blockwithme.meta.annotations.Converter)
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    @Override
    public <ANNOTATION, VALUE> AnnotationReader withValueConverter(
            final Class<ANNOTATION> annotationType,
            final Class<VALUE> valueType, final Converter<VALUE, ?, ?> converter) {
        final Map key = Collections.singletonMap(
                Objects.requireNonNull(annotationType, "annotationType"),
                Objects.requireNonNull(valueType, "valueType"));
        valueConverters
                .put(key, Objects.requireNonNull(converter, "converter"));
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#withPostProcessor(com.blockwithme.meta.annotations.PostProcessor)
     */
    @Override
    public AnnotationReader withPostProcessor(final TypeProcessor postProcessor) {
        postProcessors.add(Objects.requireNonNull(postProcessor));
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#withPostProcessor(java.lang.Class, com.blockwithme.meta.annotations.AnnotationProcessor)
     */
    @Override
    public <ANNOTATION> AnnotationReader withPostProcessor(
            final Class<ANNOTATION> annotationType,
            final AnnotationProcessor<ANNOTATION, ?> postProcessor) {
        annotationProcessors.put(
                Objects.requireNonNull(annotationType, "annotationType"),
                Objects.requireNonNull(postProcessor, "postProcessor"));
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#read(org.reflections.Reflections, java.lang.Class<? extends java.lang.annotation.Annotation>[])
     */
    @SuppressWarnings("unchecked")
    @Override
    public Map<String, AnnotatedType> read(final Reflections reflections,
            final Class<? extends Annotation>... annotations) {
        // We want to find the types to process. But we don't differentiate in
        // the parameters, between type and method annotations. So we just
        // check all possible cases.
        final HashSet<Class<?>> types = new HashSet<>();
        // For each annotation ...
        for (final Class<? extends Annotation> annotation : annotations) {
            // Check if it is on types
            types.addAll(reflections.getTypesAnnotatedWith(annotation));
            // Check if it is on fields
            for (final Field field : reflections
                    .getFieldsAnnotatedWith(annotation)) {
                types.add(field.getDeclaringClass());
            }
            // Check if it is on methods
            for (final Method method : reflections
                    .getMethodsAnnotatedWith(annotation)) {
                types.add(method.getDeclaringClass());
            }
            // Check if it is on constructors
            for (final Constructor<?> constructor : reflections
                    .getConstructorsAnnotatedWith(annotation)) {
                types.add(constructor.getDeclaringClass());
            }
        }
        // Now that we found the types, process them.
        final Map<String, AnnotatedType> result = new TreeMap<>();
        for (final Class<?> type : types) {
            result.put(type.getName(), read(type));
        }
        return result;
    }

    /** Returns all the getters for the given annotation. */
    private Method[] findGetters(final Class<?> annotation) {
        // Getters are only extracted once per type
        Method[] result = annotationMethods.get(annotation);
        if (result == null) {
            final List<Method> list = new ArrayList<>();
            for (final Method m : annotation.getDeclaredMethods()) {
                if (!m.getName().equals("annotationType")
                        && !m.getName().equals("toString")
                        && !m.getName().equals("hashCode")
                        && (m.getParameterTypes().length == 0)
                        && !m.isSynthetic()
                        && Modifier.isPublic(m.getModifiers())) {
                    list.add(m);
                }
            }
            result = list.toArray(new Method[list.size()]);
            annotationMethods.put(annotation, result);
        }
        return result;
    }

    /** Process an annotation. */
    @SuppressWarnings({ "rawtypes", "unchecked" })
    private PropMapImpl processAnnotation(final AnnotatedType annotatedType,
            final Annotation annotation, final Class<?> annotationType,
            final AnnotatedElement annotatedElement) {
        final PropMapImpl result = new PropMapImpl();
        // For each getter (== each property)
        for (final Method getter : findGetters(annotationType)) {
            final String property = getter.getName();
            // Read annotation value of property
            Object value = null;
            try {
                value = getter.invoke(annotation);
            } catch (IllegalAccessException | IllegalArgumentException
                    | InvocationTargetException e) {
                e.printStackTrace();
            }
            // Process value ...
            // First, check for a property Converter
            Converter converter = propertyConverters.get(Collections
                    .singletonMap(annotationType, property));
            if (converter != null) {
                value = converter.convert(context, annotatedType, annotation,
                        property, value);
            } else {
                // The check for a value Converter
                for (final Annotation getterAnnotation : getter
                        .getAnnotations()) {
                    converter = valueConverters.get(Collections.singletonMap(
                            unproxy(getterAnnotation.getClass()),
                            getter.getReturnType()));
                    if (converter != null) {
                        value = converter.convert(context, annotatedType,
                                annotation, property, value);
                    }
                }
            }
            // Annotation property is itself an Annotation
            if (value instanceof Annotation) {
                // recurse
                final Annotation subAnn = (Annotation) value;
                final Class<?> subAnnType = unproxy(subAnn.getClass());
                value = processAnnotation(annotatedType, subAnn, subAnnType,
                        null);
            } else if (value instanceof Annotation[]) {
                // Annotation property is itself an Annotation array
                final Annotation[] subAnn = (Annotation[]) value;
                final Class<?> subAnnType = unproxy(subAnn.getClass()
                        .getComponentType());
                final PropMapImpl[] array = new PropMapImpl[subAnn.length];
                for (int i = 0; i < subAnn.length; i++) {
                    // recurse
                    array[i] = processAnnotation(annotatedType, subAnn[i],
                            subAnnType, null);
                }
                value = array;
            }
            result.put(property, value);
        }
        // Check for a AnnotationProcessor
        final AnnotationProcessor processor = annotationProcessors
                .get(annotationType);
        if (processor != null) {
            processor.process(context, annotatedType, annotation,
                    annotatedElement, result);
        }
        return result;
    }

    /**
     * Annotation *implementations* are returned as generated proxy
     * implementing the annotation interface. But we are not interested in
     * the concrete proxy type. So we try to get back the annotation type.
     */
    private Class<?> unproxy(final Class<?> maybeProxy) {
        if (Proxy.isProxyClass(maybeProxy)) {
            final Class<?>[] interfaces = maybeProxy.getInterfaces();
            if (interfaces.length == 1) {
                return interfaces[0];
            } else if (interfaces.length > 1) {
                throw new IllegalStateException("Too many interfaces for: "
                        + maybeProxy + " " + Arrays.asList(interfaces));
            }
        }
        return maybeProxy;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.AnnotationReader#read(java.lang.Class)
     */
    @Override
    public AnnotatedType read(final Class<?> type) {
        final AnnotatedTypeImpl result = new AnnotatedTypeImpl(type);
        // First, check the getters
        for (final Method method : type.getMethods()) {
            if (!method.getDeclaringClass().getName()
                    .startsWith("com.tinkerpop")) {
                result.getMethodData(method);
                for (final Annotation annotation : method.getAnnotations()) {
                    final Class<?> annotationType = unproxy(annotation
                            .getClass());
                    result.addMethodAnnotation(
                            method,
                            annotationType,
                            processAnnotation(result, annotation,
                                    annotationType, method));
                }
            }
        }
        // Then the constructors
        for (final Constructor<?> constructor : type.getConstructors()) {
            result.getConstructorData(constructor);
            for (final Annotation annotation : constructor.getAnnotations()) {
                final Class<?> annotationType = unproxy(annotation.getClass());
                result.addConstructorAnnotation(
                        constructor,
                        annotationType,
                        processAnnotation(result, annotation, annotationType,
                                constructor));
            }
        }
        // Then the fields
        for (final Field field : type.getFields()) {
            if (!field.getDeclaringClass().getName()
                    .startsWith("com.tinkerpop.blueprints")) {
                result.getFieldData(field);
                for (final Annotation annotation : field.getAnnotations()) {
                    final Class<?> annotationType = unproxy(annotation
                            .getClass());
                    result.addFieldAnnotation(
                            field,
                            annotationType,
                            processAnnotation(result, annotation,
                                    annotationType, field));
                }
            }
        }
        // Then only the annotations on the type itself
        for (final Annotation annotation : type.getAnnotations()) {
            final Class<?> annotationType = unproxy(annotation.getClass());
            result.addTypeAnnotation(annotationType,
                    processAnnotation(result, annotation, annotationType, type));
        }
        // Finally, process the type
        for (final TypeProcessor postProcessor : postProcessors) {
            postProcessor.process(context, result);
        }
        return result;
    }
}
