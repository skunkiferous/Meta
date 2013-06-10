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
package com.blockwithme.meta;

import com.blockwithme.meta.infrastructure.HostingProvider;
import com.blockwithme.meta.infrastructure.Process;

/**
 * Life, the Universe and Everything!
 *
 * Everything is the root of everything in "meta".
 * It gives access to both static and dynamic information.
 *
 * We assume HostingProviders are statically configured...
 *
 * @author monster
 */
public interface Everything extends Configurable<Everything> {
    /** The process in which the code is currently executing ...*/
    Process currentProcess();

    /** The known HostingProviders; the root of the infrastructure. */
    HostingProvider[] providers();
}
