export const timeToMinutes = (time: string): number => {
    if (!time) return 0;
    const parts = time.split(":").map(Number);
    const hours = parts[0];
    const minutes = parts[1];
    if (hours === undefined || isNaN(hours)) return 0;
    return (hours * 60) + (minutes || 0);
};

export const minutesToTime = (minutes: number): string => {
    if (!minutes) return "00:00";
    const h = Math.floor(minutes / 60);
    const m = Math.round(minutes % 60);
    return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
};

export const calculateTotalHours = (
    moduleCount: number,
    meetingsPerModule: number,
    standardMeetingDuration: string, // HH:MM
    irregularMeetings: string[], // Array of HH:MM
): string => {
    let totalMinutes = 0;

    // Logic:
    // If not irregular: Total = Modules * MeetingsPerModule * Duration
    // If irregular: Sum of all irregular meetings

    // However, the requirement says "Encontros com irregularidade" opens a repeater.
    // If irregular toggle is ON, we sum the array.
    // If OFF, we calculate mathematically.

    if (irregularMeetings && irregularMeetings.length > 0) {
        totalMinutes = irregularMeetings.reduce(
            (acc, curr) => acc + timeToMinutes(curr),
            0,
        );
    } else {
        const meetingMinutes = timeToMinutes(standardMeetingDuration);
        totalMinutes = moduleCount * meetingsPerModule * meetingMinutes;
    }

    return minutesToTime(totalMinutes);
};
