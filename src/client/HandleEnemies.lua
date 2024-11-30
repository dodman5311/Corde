export type Enemy = {
    Instance: Instance,
    MindData: table, -- extra data the enemy might need
    MindState: string,
    Timer:table,
    Acts:table,
    Janitor:table,
}