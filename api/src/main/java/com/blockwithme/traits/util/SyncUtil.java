/*
 * Copyright (C) 2014 Sebastien Diot.
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
package com.blockwithme.traits.util;

import org.eclipse.xtext.xbase.lib.Functions;
import org.eclipse.xtext.xbase.lib.Inline;
import org.eclipse.xtext.xbase.lib.Procedures;

/**
 * Helper code, to work around lack of synchronization support in Xtend.
 *
 * @author monster
 */
public class SyncUtil {

    @Inline(value = "synchronized($1) { $2.apply($1);}", statementExpression = true)
    public static <T> void synch(final T obj,
            final Procedures.Procedure1<? super T> proc) {
        synchronized (obj) {
            proc.apply(obj);
        }
    }

    @Inline(value = "com.blockwithme.traits.util.SyncUtil.synchFunc($1,$2)")
    public static <T, R> R synchR(final T obj,
            final Functions.Function1<? super T, R> func) {
        synchronized (obj) {
            return func.apply(obj);
        }
    }

    /** Not intended to be used directly: required by synchR() */
    public static <T, R> R synchFunc(final T obj,
            final Functions.Function1<? super T, R> func) {
        synchronized (obj) {
            return func.apply(obj);
        }
    }

}
