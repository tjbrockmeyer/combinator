const fs = require('fs').promises;

(async () => {

    const newTableRegex = /Name.*\n-+\n/g;
    const rowRegex = /(?:.|\n)+?(?:\n\n|$)/g;

    const nameRegex = /([\/\|\\])?(?:([A-Za-z0-9]+)|\[([A-Z]+) *\]|(-+))/;

    const col1Width = 10;
    const col2Width = 12;
    const col3Width = 12;

    const contents = await fs.readFile('./data.txt', {encoding: 'utf-8'});

    const starts = [];
    const ends = [];
    for(const newTable of contents.matchAll(newTableRegex)) {
        starts.push(newTable.index + newTable[0].length);
        ends.push(newTable.index);
    }
    ends.push(contents.length);

    const families = starts.map((start, i) => {
        const end = ends[i + 1];
        const tableContent = contents.substring(start, end);
        const monstersInFamily = tableContent.match(rowRegex).map(row => {

            const monster = {
                name: '<Unknown>',
                baseLists: [['string']],
                secondaryLists: [['string']],
                notesLists: [['string']],
            };
            Object.assign(monster, {
                baseLists: [],
                secondaryLists: [],
                notesLists: [],
            });

            let baseList = [];
            let secondaryList = [];
            let notesList = [];

            row.split('\n').forEach(line => {
                const nameCol = line.substring(0, col1Width);
                const baseCol = line.substring(col1Width, col1Width + col2Width);
                const secondaryCol = line.substring(col1Width + col2Width, col1Width + col2Width + col3Width);
                const notesCol = line.substring(col1Width + col2Width + col3Width);

                const nameMatch = nameRegex.exec(nameCol);
                if(nameMatch) {
                    monster.name = nameMatch[2];
                }

                const col2NameMatch = nameRegex.exec(baseCol);
                if(col2NameMatch) {
                    if(!col2NameMatch[1] || col2NameMatch[1] === '/') {
                        baseList = [];
                    }
                    baseList.push(col2NameMatch[2] || col2NameMatch[3] || '?????');
                    if(!col2NameMatch[1] || col2NameMatch[1] === '\\') {
                        monster.baseLists.push(baseList);
                    }
                }

                const col3NameMatch = nameRegex.exec(secondaryCol);
                if(col3NameMatch) {
                    if(!col3NameMatch[1] || col3NameMatch[1] === '/') {
                        secondaryList = [];
                        if(notesList.length) {
                            monster.notesLists.push(notesList);
                            notesList = [];
                        }
                    }
                    secondaryList.push(col3NameMatch[2] || col3NameMatch[3] || '?????');
                    if(!col3NameMatch[1] || col3NameMatch[1] === '\\') {
                        monster.secondaryLists.push(secondaryList);
                        if(!notesCol.length) {
                            monster.notesLists.push([]);
                            notesList = [];
                        }
                    }
                }

                if(notesCol.length) {
                    notesList.push(notesCol);
                } else if(notesList.length) {
                    monster.notesLists.push(notesList);
                    notesList = [];
                }
            });

            if(notesList.length) {
                monster.notesLists.push(notesList);
            }
            return monster;
        });



        const found = monstersInFamily.find(unit => {
            return unit.baseLists.find(baseList => {
                const family = baseList.find(base => base.toUpperCase() === base);
                if(family) {
                    monstersInFamily.forEach(m => m.family = family);
                }
                return family !== undefined;
            }) !== undefined;
        });
        if(!found) {
            monstersInFamily.forEach(m => m.family = 'BOSS');
        }

        return {
            name: monstersInFamily[0].family,
            units: monstersInFamily,
        };
    });

    families.forEach(f => {
        f.units = f.units.map(m => ({
            name: m.name,
            combinations: m.baseLists.map((_, i) => ({
                base: m.baseLists[i],
                secondary: m.secondaryLists[i],
                notes: m.notesLists[i].join('\n'),
            })),
        }));
    })
    await fs.writeFile('./data.json', JSON.stringify(families, null, 2));
})();