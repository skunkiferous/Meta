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

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Map;
import java.util.Map.Entry;

import junit.framework.TestCase;

import org.reflections.Reflections;

import test.com.blockwithme.meta.A;
import test.com.blockwithme.meta.FieldAnn;
import test.com.blockwithme.meta.MethAnn;
import test.com.blockwithme.meta.MethType;
import test.com.blockwithme.meta.TypeAnn;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.AnnotationReader;
import com.blockwithme.meta.annotations.PropMap;
import com.blockwithme.meta.annotations.impl.AnnotationReaderImpl;
import com.blockwithme.meta.annotations.impl.PropMapImpl;

/**
 * @author monster
 *
 */
public class AnnotationReaderTest extends TestCase {

    /**
     * @param name
     */
    public AnnotationReaderTest(final String name) {
        super(name);
    }

    public void testAR() {
        final AnnotationReader ar = new AnnotationReaderImpl(new PropMapImpl());
        @SuppressWarnings("unchecked")
        final Map<String, AnnotatedType> result = ar.read(new Reflections(
                "test.com.blockwithme.meta"), TypeAnn.class, FieldAnn.class,
                MethAnn.class);
        assertEquals(1, result.size());
        final AnnotatedType at = result.values().iterator().next();
        assertEquals(at.getType(), A.class);
        assertEquals(0, at.getConstructors().length);

        assertEquals(1, at.getTypeData().size());
        final Entry<Class<?>, PropMap> tae = at.getTypeData().entrySet()
                .iterator().next();
        assertEquals(TypeAnn.class, tae.getKey());
        assertEquals(Collections.singletonMap("filter", new ArrayList()),
                tae.getValue());

        final Field[] fields = at.getFields();
        assertEquals(1, fields.length);
        assertEquals("CONSTANT", fields[0].getName());
        final Map<Class<?>, PropMap> faev = at.getFieldData(fields[0]);
        assertEquals(1, faev.size());
        final Entry<Class<?>, PropMap> faeve = faev.entrySet().iterator()
                .next();
        assertEquals(FieldAnn.class, faeve.getKey());
        assertEquals(Collections.singletonMap("readOnly", Boolean.TRUE),
                faeve.getValue());

        final Method[] methods = at.getMethods();
        assertEquals(1, methods.length);
        assertEquals("setName", methods[0].getName());
        final Map<Class<?>, PropMap> maev = at.getMethodData(methods[0]);
        assertEquals(1, maev.size());
        final Entry<Class<?>, PropMap> maeve = maev.entrySet().iterator()
                .next();
        assertEquals(MethAnn.class, maeve.getKey());
        assertEquals(Collections.singletonMap("value", MethType.SETTER),
                maeve.getValue());
    }
}
