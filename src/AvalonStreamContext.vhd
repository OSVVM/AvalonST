--
--  File Name:         AvalonStreamContext.vhd
--  Developer:         Tobias K
--
--  Description
--      Context Declaration for AvalonStream
--
--  This file is part of OSVVM.
--
--  Copyright (c) 2025-2026 by [OSVVM Authors](../AUTHORS.md)
--
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--

context AvalonStreamContext is
    library osvvm_common;
    context osvvm_common.OsvvmCommonContext;

    library osvvm;
    context osvvm.OsvvmContext;
    use osvvm.ScoreboardPkg_slv.all;

    library osvvm_avalonst;
    use osvvm_avalonst.AvalonStreamOptionsPkg.all;
    use osvvm_avalonst.AvalonStreamComponentPkg.all;
    use osvvm_avalonst.AvalonStreamTbPkg.all;
end context AvalonStreamContext;
